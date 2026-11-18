import SwiftUI

extension View {
    func sortDialog<Option: SortOption>(
        isPresented: Binding<Bool>,
        selection: Binding<Option>
    ) -> some View {
        actionSheet(
            isPresented: isPresented,
            title: NSLocalizedString("Sort.title", comment: ""),
            actions: Option.allCases.map { option in
                ActionSheetAction(id: option.id, title: option.title) {
                    withAnimation(.snappy(duration: 0.4)) {
                        selection.wrappedValue = option
                    }
                }
            }
        )
    }

    /// Кнопка сортировки в правой части тулбара + диалог. Выбор сохраняется снаружи (@AppStorage).
    func sortable<Option: SortOption>(selection: Binding<Option>) -> some View {
        modifier(SortableModifier(selection: selection))
    }
}

/// Кнопка сортировки для тулбара.
struct SortButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(.ic40Sort)
                .font(.ypBold17)
                .foregroundStyle(.ypBlack)
        }
        .accessibilityLabel(Text(NSLocalizedString("Sort.title", comment: "")))
    }
}

private struct SortableModifier<Option: SortOption>: ViewModifier {
    @Binding var selection: Option
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SortButton {
                        isPresented = true
                    }
                }
            }
            .sortDialog(isPresented: $isPresented, selection: $selection)
            .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct SortPreview: View {
    @AppStorage(CartSortOption.storageKey) private var sort = CartSortOption.defaultValue

    var body: some View {
        NavigationStack {
            Text(sort.title)
                .font(.ypRegular17)
                .sortable(selection: $sort)
        }
    }
}

#Preview {
    SortPreview()
}
