import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var isEditing = false
    @EnvironmentObject var settings: ProwlarrSettings
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Barra di ricerca personalizzata
                    HStack {
                        TextField("Cerca...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isSearchFieldFocused)
                            .onSubmit {
                                executeSearch()
                            }
                            .submitLabel(.search)
                        
                        Button(action: {
                            isSearchFieldFocused = false
                            executeSearch()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(searchText.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    // Contenuto principale
                    if settings.activeServer == nil {
                        ContentUnavailableView(
                            "Configurazione Necessaria",
                            systemImage: "gear",
                            description: Text("Vai nelle impostazioni per configurare il server Prowlarr")
                        )
                    } else if viewModel.searchResults.isEmpty && !searchText.isEmpty && !viewModel.isLoading && viewModel.hasSearched {
                        ContentUnavailableView(
                            "Nessun Risultato",
                            systemImage: "magnifyingglass",
                            description: Text("Nessun torrent trovato per '\(searchText)'")
                        )
                    } else if !viewModel.hasSearched {
                        ContentUnavailableView(
                            "Cerca Torrent",
                            systemImage: "magnifyingglass",
                            description: Text("Inserisci il termine di ricerca e premi invio o il pulsante cerca")
                        )
                    } else {
                        List(viewModel.searchResults) { result in
                            TorrentResultRow(result: result)
                        }
                    }
                }
                
                // Overlay di caricamento
                if viewModel.isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Ricerca in corso...")
                        .padding()
                        .background(Color.systemBackground)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
            .navigationTitle("Cerca Torrent")
            // Alert per gli errori
            .alert("Errore", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Si è verificato un errore durante la ricerca")
            }
        }
    }
    
    private func executeSearch() {
        guard !searchText.isEmpty else { return }
        Task {
            await viewModel.search(query: searchText, settings: settings)
        }
    }
}

extension Color {
    static let systemBackground = Color(UIColor.systemBackground)
}

#Preview {
    SearchView()
        .environmentObject(ProwlarrSettings())
}