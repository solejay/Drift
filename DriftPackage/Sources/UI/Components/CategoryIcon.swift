import SwiftUI
import Core

/// An icon representing a spending category
public struct CategoryIcon: View {
    private let category: SpendingCategory
    private let size: Size

    public enum Size {
        case small
        case medium
        case large

        var dimension: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 40
            case .large: return 56
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 18
            case .large: return 24
            }
        }
    }

    public init(category: SpendingCategory, size: Size = .medium) {
        self.category = category
        self.size = size
    }

    public var body: some View {
        Image(systemName: category.iconName)
            .font(.system(size: size.iconSize, weight: .medium))
            .foregroundStyle(categoryColor)
            .frame(width: size.dimension, height: size.dimension)
    }

    private var categoryColor: Color {
        DesignTokens.Colors.category(category.rawValue)
    }
}

/// Icon from category string (for use with DTOs)
public struct CategoryIconFromString: View {
    private let category: String
    private let size: CategoryIcon.Size

    public init(category: String, size: CategoryIcon.Size = .medium) {
        self.category = category
        self.size = size
    }

    public var body: some View {
        let spendingCategory = SpendingCategory(rawValue: category.lowercased()) ?? .other
        CategoryIcon(category: spendingCategory, size: size)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            CategoryIcon(category: .food, size: .small)
            CategoryIcon(category: .food, size: .medium)
            CategoryIcon(category: .food, size: .large)
        }

        HStack(spacing: 12) {
            ForEach(SpendingCategory.allCases, id: \.self) { category in
                CategoryIcon(category: category, size: .medium)
            }
        }
    }
    .padding()
}
