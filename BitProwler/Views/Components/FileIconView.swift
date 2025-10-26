import SwiftUI

struct FileIconView: View {
    let filename: String
    let isDirectory: Bool

    init(filename: String, isDirectory: Bool = false) {
        self.filename = filename
        self.isDirectory = isDirectory
    }
    
    var body: some View {
        Image(systemName: iconNameForFile())
            .font(.title2)
            .frame(width: 30, alignment: .center)
            .foregroundColor(.accentColor)
    }
    
    private func iconNameForFile() -> String {
        if isDirectory {
            return "folder.fill"
        }
        
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "mkv", "mp4", "avi", "mov", "wmv", "flv":
            return "film.fill"
        case "mp3", "flac", "aac", "wav", "ogg":
            return "music.note"
        case "jpg", "jpeg", "png", "gif", "bmp", "heic":
            return "photo.fill"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        case "txt", "md", "nfo":
            return "doc.text.fill"
        case "pdf":
            return "doc.richtext.fill"
        case "srt", "sub":
            return "captions.bubble.fill"
        default:
            return "doc"
        }
    }
}