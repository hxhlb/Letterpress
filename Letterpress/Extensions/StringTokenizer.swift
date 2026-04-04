//
//  StringTokenizer.swift
//  Letterpress
//
//  Created by 82Flex on 6/15/25.
//

import CoreFoundation
import NaturalLanguage

extension String {
    /// 按 CJK 字符/英文单词混合分割
    func hudTokenized(
        byCharacter: Bool = false,
        minimumCount: Int = 0,
        shuffled: Bool = false
    ) -> [String] {
        var result: [String] = []
        let string = self
        let nsString = string as NSString
        let length = nsString.length
        if let cfTokenizer = CFStringTokenizerCreate(nil, string as CFString, CFRangeMake(0, length), kCFStringTokenizerUnitWord, nil) {
            var tokenType = CFStringTokenizerAdvanceToNextToken(cfTokenizer)
            while tokenType != [] {
                let range = CFStringTokenizerGetCurrentTokenRange(cfTokenizer)
                let token = nsString.substring(with: NSRange(location: range.location, length: range.length))
                if byCharacter, token.rangeOfCharacter(from: .cjkCharacterSet) != nil {
                    token.forEach { result.append(String($0)) }
                } else if !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result.append(token)
                }
                tokenType = CFStringTokenizerAdvanceToNextToken(cfTokenizer)
            }
        } else {
            // fallback: 按字符
            string.forEach { result.append(String($0)) }
        }
        if !result.isEmpty {
            // 确保结果至少有 minimumCount 个元素
            while result.count < minimumCount {
                result += result
            }
        }
        return shuffled ? result.shuffled() : result
    }
}

extension CharacterSet {
    /// CJK 相关字符集
    static let cjkCharacterSet: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "\u{4E00}"..."\u{9FFF}") // CJK Unified Ideographs
        set.insert(charactersIn: "\u{F900}"..."\u{FAFF}") // CJK Compatibility Ideographs
        set.insert(charactersIn: "\u{3000}"..."\u{303F}") // Japanese-style punctuation
        set.insert(charactersIn: "\u{3040}"..."\u{309F}") // Hiragana
        set.insert(charactersIn: "\u{30A0}"..."\u{30FF}") // Katakana
        set.insert(charactersIn: "\u{31F0}"..."\u{31FF}") // Katakana Phonetic Extensions
        set.insert(charactersIn: "\u{AC00}"..."\u{D7AF}") // Hangul Syllables
        set.insert(charactersIn: "\u{1100}"..."\u{11FF}") // Hangul Jamo
        set.insert(charactersIn: "\u{3130}"..."\u{318F}") // Hangul Compatibility Jamo
        return set
    }()
}
