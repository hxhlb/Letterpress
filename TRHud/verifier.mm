#ifndef ALLOW_PROTECTED
#define ALLOW_PROTECTED 1
#endif

#import "TRHudCore.h"
#import <Foundation/Foundation.h>
#import <getopt.h>

// Print usage information
void printUsage(const char *programName) {
    printf("Usage: %s <command> [file]\n", programName);
    printf("Commands:\n");
    printf("  dump            Dump entitlements from the Mach-O file\n");
    printf("    -o, --out     Output to file instead of stdout\n");
    printf("  protect         Protect the Mach-O file by updating LC_UUID with TEXT hash\n");
    printf("  verify          Verify the Mach-O file integrity\n");
    printf("  help            Display this help message\n");
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        // Check if command is provided
        if (argc < 2) {
            fprintf(stderr, "Error: No command specified\n");
            printUsage(argv[0]);
            return EXIT_FAILURE;
        }

        // Get the command
        NSString *command = [NSString stringWithUTF8String:argv[1]];

        // Check if help is requested
        if ([command isEqualToString:@"help"]) {
            printUsage(argv[0]);
            return EXIT_SUCCESS;
        }

        TRHudCore *verifier = [TRHudCore new];

        // Handle dump command with options
        if ([command isEqualToString:@"dump"]) {
            // Reset getopt
            optind = 2; // Start from the arguments after "dump"

            // Define options for dump command
            static struct option dump_options[] = {{"out", required_argument, 0, 'o'}, {NULL, 0, 0, 0}};

            char *outfile = NULL;
            int option;

            // Parse dump command options
            while ((option = getopt_long(argc, argv, "o:", dump_options, NULL)) != -1) {
                switch (option) {
                case 'o':
                    outfile = optarg;
                    break;
                default:
                    fprintf(stderr, "Error: Invalid option for dump command\n");
                    printUsage(argv[0]);
                    return EXIT_FAILURE;
                }
            }

            // Check if we have a file path
            if (optind >= argc) {
                fprintf(stderr, "Error: No Mach-O file specified\n");
                printUsage(argv[0]);
                return EXIT_FAILURE;
            }

            // Get the file path
            NSString *filePath = [NSString stringWithUTF8String:argv[optind]];

            // Check if the file exists
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                fprintf(stderr, "Error: File does not exist: %s\n", [filePath UTF8String]);
                return EXIT_FAILURE;
            }

            // Check if the file is a Mach-O file
            if (![verifier isMachOFile:filePath]) {
                fprintf(stderr, "[x] %s: not a Mach-O file\n", [filePath fileSystemRepresentation]);
                return EXIT_FAILURE;
            }

            // Check if the file is a Mach-O executable
            if (![verifier isMachOExecutable:filePath]) {
                // Nothing to dump
                return EXIT_SUCCESS;
            }

            NSData *entData = [verifier dumpEntitlementsDataOfAnyArch:filePath];
            BOOL result = entData != nil;

            if (result) {
                if (outfile) {
                    // Write to file
                    FILE *file = fopen(outfile, "w");
                    if (!file) {
                        fprintf(stderr, "Error: Cannot open output file: %s\n", outfile);
                        return EXIT_FAILURE;
                    }
                    fwrite([entData bytes], 1, [entData length], file);
                    fclose(file);
                    printf("Entitlements written to %s\n", outfile);
                } else {
                    // Write to stdout
                    fputs((const char *)[entData bytes], stdout);
                }
            }

            return result ? EXIT_SUCCESS : EXIT_FAILURE;
        }

        // Check if we have a file path for other commands
        if (argc < 3) {
            fprintf(stderr, "Error: No Mach-O file specified\n");
            printUsage(argv[0]);
            return EXIT_FAILURE;
        }

        // Get the file path
        NSString *filePath = [NSString stringWithUTF8String:argv[2]];

        // Check if the file exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            fprintf(stderr, "Error: File does not exist: %s\n", [filePath UTF8String]);
            return EXIT_FAILURE;
        }

        // Check if the file is a Mach-O file
        if (![verifier isMachOFile:filePath]) {
            fprintf(stderr, "[x] %s: not a Mach-O file\n", [filePath fileSystemRepresentation]);
            return EXIT_FAILURE;
        }

        // Execute operations based on command
        BOOL result = NO;

        if ([command isEqualToString:@"protect"]) {
            result = [verifier protectMachOFile:filePath];
            if (result) {
                printf("[^] %s: protected\n", [filePath fileSystemRepresentation]);
            } else {
                fprintf(stderr, "[x] %s: failed\n", [filePath fileSystemRepresentation]);
            }
        } else if ([command isEqualToString:@"verify"]) {
            result = [verifier verifyMachOFile:filePath];
            if (result) {
                printf("[^] %s: valid\n", [filePath fileSystemRepresentation]);
            } else {
                fprintf(stderr, "[x] %s: invalid\n", [filePath fileSystemRepresentation]);
            }
        } else {
            fprintf(stderr, "Error: Unknown command: %s\n", [command UTF8String]);
            printUsage(argv[0]);
            return EXIT_FAILURE;
        }

        return result ? EXIT_SUCCESS : EXIT_FAILURE;
    }
}
