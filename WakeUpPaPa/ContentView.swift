
import Combine
import SwiftUI
import UserNotifications

// 1. 알람 데이터 모델
struct Alarm: Identifiable, Codable {
    var id = UUID()
    var time: Date
    var isOn: Bool
    var label: String
}

// 2. 알람 관리 매니저 (데이터 보관 및 실제 알림 등록)
class AlarmManager: ObservableObject {
    @Published var alarms: [Alarm] = []
    
    // 알림 권한 요청
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
            if success { print("알림 권한 허용됨") }
        }
    }
    
    // [중요] 실제 시스템에 알람을 등록하는 함수
    func scheduleNotification(alarm: Alarm) {
        // 알람이 꺼져있으면 예약하지 않음
        guard alarm.isOn else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "알람"
        content.body = alarm.label
        content.sound = .default // 기본 알림음
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: alarm.time)
        
        // 날짜가 매칭될 때마다 반복 (매일 그 시간)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 등록 에러: \(error.localizedDescription)")
            } else {
                print("알림 예약 성공: \(components.hour!):\(components.minute!)")
            }
        }
    }
}

// 3. 메인 화면
struct ContentView: View {
    @StateObject var manager = AlarmManager()
    @State private var isShowingAddAlarm = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach($manager.alarms) { $alarm in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(alarm.time, style: .time)
                                .font(.system(size: 40, weight: .light))
                            Text(alarm.label)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        // 토글을 껐다 켤 때도 알림 예약을 갱신해야 합니다.
                        Toggle("", isOn: $alarm.isOn)
                            .labelsHidden()
                            .onChange(of: alarm.isOn) { _, newValue in
                                if newValue {
                                    manager.scheduleNotification(alarm: alarm)
                                } else {
                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
                                }
                            }
                    }
                    .padding(.vertical, 8)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let id = manager.alarms[index].id.uuidString
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
                    }
                    manager.alarms.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("알람")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingAddAlarm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddAlarm) {
                AddAlarmView(manager: manager)
            }
            .onAppear {
                manager.requestPermission()
            }
        }
    }
}

// 4. 알람 추가 화면
struct AddAlarmView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: AlarmManager
    @State private var selectedDate = Date()
    @State private var label = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("시간 선택", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                Section {
                    TextField("알람 레이블", text: $label)
                }
            }
            .navigationTitle("새 알람")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        let newAlarm = Alarm(time: selectedDate, isOn: true, label: label.isEmpty ? "알람" : label)
                        
                        // [핵심] 리스트에 추가하고 + 동시에 알림 예약 함수 호출
                        manager.alarms.append(newAlarm)
                        manager.scheduleNotification(alarm: newAlarm)
                        
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
