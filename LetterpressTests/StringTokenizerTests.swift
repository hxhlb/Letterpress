//
//  StringTokenizerTests.swift
//  Letterpress
//
//  Created by 82Flex on 6/15/25.
//

import XCTest
@testable import Letterpress

final class StringTokenizerTests: XCTestCase {
    func testPureEnglish() {
        let text = "The quick brown fox jumps over the lazy dog."
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["The", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"])
    }

    func testPureChinese() {
        let text = "今天天气很好"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["今", "天", "天", "气", "很", "好"])
    }

    func testChineseEnglishMixed() {
        let text = "你好 world"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["你", "好", "world"])
    }

    func testPureJapanese() {
        let text = "こんにちは世界"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["こ", "ん", "に", "ち", "は", "世", "界"])
    }

    func testJapaneseEnglishMixed() {
        let text = "こんにちは world"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["こ", "ん", "に", "ち", "は", "world"])
    }

    func testPureKorean() {
        let text = "안녕하세요세계"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["안", "녕", "하", "세", "요", "세", "계"])
    }

    func testKoreanEnglishMixed() {
        let text = "안녕하세요 world"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["안", "녕", "하", "세", "요", "world"])
    }

    func testEnglishWithPunctuation() {
        let text = "Hello, world! How's it going?"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["Hello", "world", "How's", "it", "going"])
    }

    func testEnglishWithHyphen() {
        let text = "State-of-the-art technology."
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["State", "of", "the", "art", "technology"])
    }

    func testChineseWithPunctuation() {
        let text = "你好，世界！今天天气很好。"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["你", "好", "世", "界", "今", "天", "天", "气", "很", "好"])
    }

    func testChineseEnglishMixedWithPunctuation() {
        let text = "你好, world!"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["你", "好", "world"])
    }

    func testJapaneseWithPunctuation() {
        let text = "こんにちは、世界！"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["こ", "ん", "に", "ち", "は", "世", "界"])
    }

    func testJapaneseEnglishMixedWithPunctuation() {
        let text = "こんにちは, world!"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["こ", "ん", "に", "ち", "は", "world"])
    }

    func testKoreanWithPunctuation() {
        let text = "안녕하세요, 세계!"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["안", "녕", "하", "세", "요", "세", "계"])
    }

    func testKoreanEnglishMixedWithPunctuation() {
        let text = "안녕하세요, world!"
        let tokens = text.hudTokenized()
        XCTAssertEqual(tokens, ["안", "녕", "하", "세", "요", "world"])
    }
}
