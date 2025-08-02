import SwiftUI

struct AddFilterView: View {
    @Environment(\.dismiss) var dismiss
    let filterViewModel: FilterViewModel
    
    @State private var name = ""
    @State private var keyword = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dettagli Filtro")) {
                    TextField("Nome", text: $name)
                    TextField("Keyword", text: $keyword)
                }
                
                Section {
                    Button("Salva") {
                        let filter = TorrentFilter(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            keyword: keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        filterViewModel.addFilter(filter)
                        dismiss()
                    }
                    .disabled(name.isEmpty || keyword.isEmpty)
                }
            }
            .navigationTitle("Nuovo Filtro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
        }
    }
} 