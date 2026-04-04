//
//  View+Modify.swift
//  Letterpress
//
//  Created by 82Flex on 6/15/25.
//

import SwiftUI

extension View {
    func modify<Content: View>(
        @ViewBuilder _ transform: (Self) -> Content
    ) -> some View {
        return transform(self)
    }
}
