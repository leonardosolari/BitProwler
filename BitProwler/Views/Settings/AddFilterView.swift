import SwiftUI

struct AddFilterView: View {
    @Environment(\.dismiss) var dismiss
    let filterViewModel: FilterViewModel
    
    @State private var name = ""
    @State private var keyword = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filter Details")) {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("filter_name_field")
                    TextField("Keyword", text: $keyword)
                        .accessibilityIdentifier("filter_keyword_field")
                }
                
                Section {
                    Button("Save") {
                        let filter = TorrentFilter(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            keyword: keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        filterViewModel.addFilter(filter)
                        dismiss()
                    }
                    .disabled(name.isEmpty || keyword.isEmpty)
                    .accessibilityIdentifier("save_filter_button")
                }
            }
            .navigationTitle("New Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}