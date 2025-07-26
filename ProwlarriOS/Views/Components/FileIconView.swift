// File: /ProwlarriOS/Views/Components/FileIconView.swift

import SwiftUI

struct FileIconView: View {
    let filename: String
    
    var body: some View {
        Image(systemName: iconNameForFile())
            .font(.title2)
            .frame(width: 30, alignment: .center)
            .foregroundColor(.accentColor)
    }
    
    private func iconNameForFile() -> String {
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        // Video
        case "mkv", "mp4", "avi", "mov", "wmv", "flv":
            return "film.fill"
        // Audio
        case "mp3", "flac", "aac", "wav", "ogg":
            return "music.note"
        // Immagini
        case "jpg", "jpeg", "png", "gif", "bmp", "heic":
            return "photo.fill"
        // Archivi
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        // Documenti
        case "txt", "md", "nfo":
            return "doc.text.fill"
        case "pdf":
            return "doc.richtext.fill"
        // Sottotitoli
        case "srt", "sub":
            return "captions.bubble.fill"
        // Default
        default:
            return "doc"
        }
    }
}