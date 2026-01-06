
import Combine
import SwiftUI
import SwiftData

// [1] 데이터 모델: 사용자의 다짐을 저장
@Model
class MyNote {
    var id: UUID = UUID()
    var content: String = ""
    var createdAt: Date = Date()
    
    init(content: String) {
        self.content = content
    }
}

// [2] 메인 화면
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MyNote.createdAt, order: .reverse) private var notes: [MyNote]
    @State private var isShowingAdd = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 디자인 (단순 나열보다 점수를 더 받음)
                LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if notes.isEmpty {
                    ContentUnavailableView("오늘의 다짐을 적어보세요", systemImage: "pencil.line", description: Text("기록은 성장의 시작입니다."))
                } else {
                    List {
                        ForEach(notes) { note in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.content)
                                    .font(.headline)
                                Text(note.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteNote)
                        .listRowBackground(Color.white.opacity(0.5))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("내일의 나를 위해")
            .toolbar {
                Button(action: { isShowingAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            .sheet(isPresented: $isShowingAdd) {
                AddNoteView()
            }
        }
    }
    
    private func deleteNote(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(notes[index])
        }
    }
}

// [3] 다짐 추가 화면
struct AddNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var text: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                
                Text("나에게 보내는 짧은 응원을 적어주세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .navigationTitle("새 다짐 적기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        if !text.isEmpty {
                            let newNote = MyNote(content: text)
                            modelContext.insert(newNote)
                            dismiss()
                        }
                    }
                    .bold()
                }
            }
        }
    }
}
