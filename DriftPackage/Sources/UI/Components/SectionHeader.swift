import SwiftUI

/// Reusable section header with uppercase text and letter spacing
public struct SectionHeader: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .sectionHeaderStyle()
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        SectionHeader("By Category")
        SectionHeader("Top Merchants")
        SectionHeader("Recent Transactions")
    }
    .padding()
}
