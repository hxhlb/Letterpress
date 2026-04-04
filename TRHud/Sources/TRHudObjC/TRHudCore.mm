#import "TRHudCore.h"

#import <mach-o/fat.h>
#import <mach-o/loader.h>

#define TAG "TRHudCore : "

#if DEBUG
#define DRMLog(...) NSLog(__VA_ARGS__)
#else
#define DRMLog(...)
#endif

// Code signature related structures and constants
#define CSSLOT_ENTITLEMENTS 5
#define CSMAGIC_EMBEDDED_ENTITLEMENTS 0xfade7171
#define CSMAGIC_SUPERBLOB 0xfade0cc0

typedef struct {
    uint32_t type;
    uint32_t offset;
} CS_BlobIndex;

typedef struct {
    uint32_t magic;
    uint32_t length;
    uint32_t count;
    CS_BlobIndex index[];
} CS_SuperBlob;

typedef struct {
    uint32_t magic;
    uint32_t length;
} CS_GenericBlob;

// Simple 128-bit hash function implementation
NS_INLINE void TRSimpleHash128(const void *data, size_t length, unsigned char *out) {
    // Initial seed for first 64 bits
    uint64_t h1 = 0x6a09e667f3bcc908ULL;
    // Initial seed for second 64 bits
    uint64_t h2 = 0xbb67ae8584caa73bULL;

    // Prime multipliers
    const uint64_t m1 = 0x00000100000001B3ULL; // Prime number for mixing
    const uint64_t m2 = 0x0000010000000001ULL; // Another prime for mixing

    const unsigned char *bytes = (const unsigned char *)data;

    // Process each byte of the data
    for (size_t i = 0; i < length; i++) {
        h1 ^= bytes[i];
        h1 *= m1;
        h1 ^= h1 >> 33;

        h2 ^= bytes[i];
        h2 *= m2;
        h2 ^= h2 >> 33;

        // Cross-mixing for better avalanche effect
        if (i % 8 == 0) {
            uint64_t temp = h1;
            h1 = (h1 ^ h2) * m1;
            h2 = (h2 ^ temp) * m2;
        }
    }

    // Final mixing
    h1 ^= length;
    h2 ^= length;

    h1 += h2;
    h2 += h1;

    // Store the hash
    memcpy(out, &h1, 8);
    memcpy(out + 8, &h2, 8);
}

NS_INLINE BOOL TRIsMachO(FILE *machoFile) {
    struct mach_header_64 mh;
    long currentPos = ftell(machoFile);
    fread(&mh, sizeof(mh), 1, machoFile);
    fseek(machoFile, currentPos, SEEK_SET);
    return (mh.magic == MH_MAGIC_64 || mh.magic == MH_CIGAM_64 || mh.magic == FAT_MAGIC || mh.magic == FAT_CIGAM);
}

NS_INLINE BOOL TRIsMachOExecutable(FILE *machoFile) {
    struct mach_header_64 mh;
    long currentPos = ftell(machoFile);
    fread(&mh, sizeof(mh), 1, machoFile);
    fseek(machoFile, currentPos, SEEK_SET);
    return (mh.magic == MH_MAGIC_64 || mh.magic == MH_CIGAM_64 || mh.magic == FAT_MAGIC || mh.magic == FAT_CIGAM) &&
           (mh.filetype == MH_EXECUTE);
}

__used NS_INLINE void TRMachOEnumerateArchs(FILE *machoFile,
                                            void (^archEnumBlock)(struct fat_arch *arch, uint32_t archMetadataOffset,
                                                                  uint32_t archOffset, BOOL *stop)) {
    struct mach_header_64 mh;
    fseek(machoFile, 0, SEEK_SET);
    fread(&mh, sizeof(mh), 1, machoFile);

    if (mh.magic == FAT_MAGIC || mh.magic == FAT_CIGAM) {
        struct fat_header fh;
        fseek(machoFile, 0, SEEK_SET);
        fread(&fh, sizeof(fh), 1, machoFile);

        for (int i = 0; i < OSSwapBigToHostInt32(fh.nfat_arch); i++) {
            uint32_t archMetadataOffset = sizeof(fh) + sizeof(struct fat_arch) * i;
            struct fat_arch fatArch;
            fseek(machoFile, archMetadataOffset, SEEK_SET);
            fread(&fatArch, sizeof(fatArch), 1, machoFile);

            BOOL stop = NO;
            archEnumBlock(&fatArch, archMetadataOffset, OSSwapBigToHostInt32(fatArch.offset), &stop);
            if (stop)
                break;
        }
    } else if (mh.magic == MH_MAGIC_64 || mh.magic == MH_CIGAM_64) {
        BOOL stop;
        archEnumBlock(NULL, 0, 0, &stop);
    }
}

NS_INLINE void TRMachOEnumerateLoadCommands(FILE *machoFile, uint32_t archOffset,
                                            void (^enumerateBlock)(struct load_command cmd, uint32_t cmdOffset,
                                                                   BOOL *stop)) {
    struct mach_header_64 mh;
    fseek(machoFile, archOffset, SEEK_SET);
    fread(&mh, sizeof(mh), 1, machoFile);

    uint32_t nCmds = OSSwapLittleToHostInt32(mh.ncmds);
    uint32_t sizeOfCmds = OSSwapLittleToHostInt32(mh.sizeofcmds);
    uint32_t offset = 0;

    for (uint32_t i = 0; i < nCmds && offset < sizeOfCmds; i++) {
        uint32_t absoluteOffset = archOffset + sizeof(mh) + offset;
        struct load_command cmd;
        fseek(machoFile, absoluteOffset, SEEK_SET);
        fread(&cmd, sizeof(cmd), 1, machoFile);
        BOOL stop = NO;
        enumerateBlock(cmd, absoluteOffset, &stop);
        if (stop)
            break;
        offset += OSSwapLittleToHostInt32(cmd.cmdsize);
    }
}

__used NS_INLINE NSData *TRCalculateHashForTextSection(FILE *file, uint32_t archOffset) {
    __block NSData *textSectionHash = nil;
    __block BOOL foundTextSection = NO;
    __block uint64_t textOffset = 0;
    __block uint64_t textSize = 0;

    // Find __TEXT segment
    TRMachOEnumerateLoadCommands(file, archOffset, ^(struct load_command cmd, uint32_t cmdOffset, BOOL *stop) {
      if (OSSwapLittleToHostInt32(cmd.cmd) == LC_SEGMENT_64) {
          struct segment_command_64 segCmd;
          fseek(file, cmdOffset, SEEK_SET);
          fread(&segCmd, sizeof(segCmd), 1, file);

          // Check if this is the __TEXT segment
          if (strncmp(segCmd.segname, "__TEXT", 16) == 0) {
              uint32_t nsects = OSSwapLittleToHostInt32(segCmd.nsects);
              uint32_t sectionOffset = cmdOffset + sizeof(struct segment_command_64);

              // Find __text section
              for (uint32_t i = 0; i < nsects; i++) {
                  struct section_64 sect;
                  fseek(file, sectionOffset + i * sizeof(struct section_64), SEEK_SET);
                  fread(&sect, sizeof(sect), 1, file);

                  if (strncmp(sect.sectname, "__text", 16) == 0) {
                      textOffset = OSSwapLittleToHostInt64(sect.offset);
                      textSize = OSSwapLittleToHostInt64(sect.size);
                      foundTextSection = YES;
                      *stop = YES;
                      break;
                  }
              }
          }
      }
    });

    if (foundTextSection && textSize > 0) {
        // Read the content of the __text section
        unsigned char *textData = (unsigned char *)malloc(textSize);
        fseek(file, textOffset, SEEK_SET);
        fread(textData, textSize, 1, file);

        // Calculate 128-bit hash
        unsigned char hashResult[16]; // 128 bits
        TRSimpleHash128(textData, textSize, hashResult);

        // Create NSData object
        textSectionHash = [NSData dataWithBytes:hashResult length:16];
        free(textData);
    }

    return textSectionHash;
}

@implementation TRHudCore

- (BOOL)isMachOFile:(NSString *)filePath {
    if (!filePath) {
        return NO;
    }

    FILE *machoFile = fopen(filePath.fileSystemRepresentation, "rb");
    if (!machoFile) {
        DRMLog(@TAG "Failed to open file: %@", filePath);
        return NO;
    }

    BOOL isMachO = TRIsMachO(machoFile);
    fclose(machoFile);
    return isMachO;
}

- (BOOL)isMachOExecutable:(NSString *)filePath {
    if (!filePath) {
        return NO;
    }

    FILE *machoFile = fopen(filePath.fileSystemRepresentation, "rb");
    if (!machoFile) {
        DRMLog(@TAG "Failed to open file: %@", filePath);
        return NO;
    }

    BOOL isMachOExecutable = TRIsMachOExecutable(machoFile);
    fclose(machoFile);
    return isMachOExecutable;
}

#if ALLOW_PROTECTED
- (BOOL)protectMachOFile:(NSString *)filePath {
    if (!filePath) {
        return NO;
    }

    // Create temporary file path
    NSString *tempFilePath = [NSTemporaryDirectory()
        stringByAppendingPathComponent:[NSString stringWithFormat:@"macho_temp_%@", [[NSUUID UUID] UUIDString]]];

    // Copy source file to temporary location
    NSError *copyError = nil;
    [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:tempFilePath error:&copyError];
    if (copyError) {
        DRMLog(@TAG "Failed to create temporary file: %@", copyError);
        return NO;
    }

    // Open temporary file for reading
    FILE *machoFile = fopen(filePath.fileSystemRepresentation, "rb");
    if (!machoFile) {
        DRMLog(@TAG "Failed to open temporary file: %@", tempFilePath);
        [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
        return NO;
    }

    __block BOOL success = YES;
    __block uint32_t archCount = 0;

    // Enumerate all architectures
    TRMachOEnumerateArchs(machoFile,
                          ^(struct fat_arch *arch, uint32_t archMetadataOffset, uint32_t archOffset, BOOL *stop) {
                            archCount += 1;

                            // Calculate hash for __TEXT segment
                            NSData *textHash = TRCalculateHashForTextSection(machoFile, archOffset);

                            if (!textHash) {
                                DRMLog(@TAG "Failed to calculate hash for architecture #%u", archOffset);
                                success = NO;
                                *stop = YES;
                                return;
                            }

                            __block BOOL foundUUID = NO;

                            // Find LC_UUID command
                            TRMachOEnumerateLoadCommands(
                                machoFile, archOffset, ^(struct load_command cmd, uint32_t cmdOffset, BOOL *cmdStop) {
                                  if (OSSwapLittleToHostInt32(cmd.cmd) == LC_UUID) {
                                      // UUID offset
                                      uint32_t uuidOffset = cmdOffset + offsetof(struct uuid_command, uuid);

                                      // Open temporary file in read+write mode to modify
                                      FILE *writeFile = fopen(tempFilePath.fileSystemRepresentation, "r+b");
                                      if (writeFile) {
                                          fseek(writeFile, uuidOffset, SEEK_SET);
                                          fwrite(textHash.bytes, textHash.length, 1, writeFile);
                                          fclose(writeFile);
                                          foundUUID = YES;
                                      } else {
                                          DRMLog(@TAG "Failed to open temporary file for writing");
                                          success = NO;
                                      }

                                      *cmdStop = YES;
                                  }
                                });

                            if (!foundUUID) {
                                DRMLog(@TAG "LC_UUID command not found in architecture #%u", archOffset);
                                success = NO;
                                *stop = YES;
                            }
                          });

    fclose(machoFile);

    // If modification was successful, replace original file with the temporary
    // one
    if (success && archCount > 0) {
        NSError *replaceError = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        [[NSFileManager defaultManager] moveItemAtPath:tempFilePath toPath:filePath error:&replaceError];
        if (replaceError) {
            DRMLog(@TAG "Failed to replace original file with modified one: %@", replaceError);
            success = NO;
        }
    } else {
        // Clean up temporary file
        [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
    }

    return success && (archCount > 0);
}
#endif

- (BOOL)verifyMachOFile:(NSString *)filePath {
    if (!filePath) {
        return NO;
    }

    FILE *machoFile = fopen(filePath.fileSystemRepresentation, "rb");
    if (!machoFile) {
        DRMLog(@TAG "Failed to open file: %@", filePath);
        return NO;
    }

    __block uint32_t validArchCount = 0;
    __block uint32_t totalArchCount = 0;

    // Enumerate all architectures
    TRMachOEnumerateArchs(
        machoFile, ^(struct fat_arch *arch, uint32_t archMetadataOffset, uint32_t archOffset, BOOL *stop) {
          totalArchCount += 1;

          // Calculate hash for __TEXT segment
          NSData *textHash = TRCalculateHashForTextSection(machoFile, archOffset);

          if (!textHash) {
              DRMLog(@TAG "Failed to calculate hash for architecture #%u", archOffset);
              *stop = YES;
              return;
          }

          __block BOOL foundUUID = NO;
          __block BOOL uuidValid = NO;

          // Find LC_UUID command
          TRMachOEnumerateLoadCommands(
              machoFile, archOffset, ^(struct load_command cmd, uint32_t cmdOffset, BOOL *cmdStop) {
                if (OSSwapLittleToHostInt32(cmd.cmd) == LC_UUID) {
                    struct uuid_command uuidCmd;
                    fseek(machoFile, cmdOffset, SEEK_SET);
                    fread(&uuidCmd, sizeof(uuidCmd), 1, machoFile);

                    // Compare calculated hash with stored UUID
                    NSData *storedUUID = [NSData dataWithBytes:uuidCmd.uuid length:16];
                    uuidValid = [textHash isEqualToData:storedUUID];
                    foundUUID = YES;

                    if (uuidValid) {
                        DRMLog(@TAG "UUID verification succeeded for architecture #%u: %@", archOffset, storedUUID);
                    }

                    *cmdStop = YES;
                }
              });

          if (!foundUUID) {
              DRMLog(@TAG "LC_UUID command not found in architecture #%u", archOffset);
          } else if (!uuidValid) {
              DRMLog(@TAG "UUID verification failed for architecture #%u", archOffset);
          }

          if (!foundUUID || !uuidValid) {
              *stop = YES;
          } else {
              validArchCount += 1;
          }
        });

    fclose(machoFile);

    return (validArchCount == totalArchCount) && totalArchCount > 0;
}

#if ALLOW_PROTECTED
- (NSData *)dumpEntitlementsDataOfAnyArch:(NSString *)filePath {
    if (!filePath) {
        return nil;
    }

    FILE *machoFile = fopen(filePath.fileSystemRepresentation, "rb");
    if (!machoFile) {
        DRMLog(@TAG "Failed to open file: %@", filePath);
        return nil;
    }

    __block NSData *entitlementsData = nil;

    // Enumerate all architectures
    TRMachOEnumerateArchs(
        machoFile, ^(struct fat_arch *arch, uint32_t archMetadataOffset, uint32_t archOffset, BOOL *stop) {
          // Find code signature
          __block uint32_t signatureOffset = 0;
          __block uint32_t signatureSize = 0;
          __block BOOL foundCodeSignature = NO;

          TRMachOEnumerateLoadCommands(machoFile, archOffset,
                                       ^(struct load_command cmd, uint32_t cmdOffset, BOOL *cmdStop) {
                                         if (OSSwapLittleToHostInt32(cmd.cmd) == LC_CODE_SIGNATURE) {
                                             struct linkedit_data_command linkEditCmd;
                                             fseek(machoFile, cmdOffset, SEEK_SET);
                                             fread(&linkEditCmd, sizeof(linkEditCmd), 1, machoFile);

                                             signatureOffset = OSSwapLittleToHostInt32(linkEditCmd.dataoff);
                                             signatureSize = OSSwapLittleToHostInt32(linkEditCmd.datasize);

                                             foundCodeSignature = YES;
                                             *cmdStop = YES;
                                         }
                                       });

          if (foundCodeSignature && signatureSize > 0) {
              // Read code signature data
              unsigned char *signatureData = (unsigned char *)malloc(signatureSize);
              if (!signatureData) {
                  return;
              }

              fseek(machoFile, signatureOffset, SEEK_SET);
              fread(signatureData, signatureSize, 1, machoFile);

              // Parse SuperBlob structure
              CS_SuperBlob *superBlob = (CS_SuperBlob *)signatureData;
              if (OSSwapBigToHostInt32(superBlob->magic) == CSMAGIC_SUPERBLOB) {
                  uint32_t blobCount = OSSwapBigToHostInt32(superBlob->count);

                  // Find entitlements blob
                  for (uint32_t i = 0; i < blobCount; i++) {
                      CS_BlobIndex index = superBlob->index[i];
                      uint32_t blobType = OSSwapBigToHostInt32(index.type);
                      uint32_t blobOffset = OSSwapBigToHostInt32(index.offset);

                      if (blobType == CSSLOT_ENTITLEMENTS) {
                          // Found entitlements
                          CS_GenericBlob *entitlementsBlob = (CS_GenericBlob *)(signatureData + blobOffset);
                          uint32_t blobMagic = OSSwapBigToHostInt32(entitlementsBlob->magic);
                          uint32_t blobLength = OSSwapBigToHostInt32(entitlementsBlob->length);

                          if (blobMagic == CSMAGIC_EMBEDDED_ENTITLEMENTS && blobLength > sizeof(CS_GenericBlob)) {
                              // Extract entitlements data (XML plist)
                              uint32_t dataOffset = sizeof(CS_GenericBlob);
                              uint32_t dataLength = blobLength - dataOffset;

                              entitlementsData = [NSData dataWithBytes:(signatureData + blobOffset + dataOffset)
                                                                length:dataLength];
                              *stop = YES;
                          }
                      }
                  }
              }

              free(signatureData);

              if (entitlementsData) {
                  *stop = YES;
              }
          }
        });

    fclose(machoFile);

    // Check for "<?xml" to ensure it's a valid XML plist
    if (entitlementsData && entitlementsData.length > 5) {
        const char *dataBytes = (const char *)entitlementsData.bytes;
        if (strncmp(dataBytes, "<?xml", 5) != 0) {
            entitlementsData = nil; // Not a valid XML plist
        }
    }

    return entitlementsData;
}
#endif

@end
