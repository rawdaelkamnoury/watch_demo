import SwiftUI

struct ContentView: View {
   @ObservedObject var viewModel: WatchViewModel = WatchViewModel()
    let currentDate = Date()
       
    func formatDate(date: Date) -> String {
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = "EE, d MMM yyyy"
           return dateFormatter.string(from: date)
       }
      var body: some View {
          VStack {
              Text("\(viewModel.counter) BPM")
                  .padding().font(.title)
              Text("\(formatDate(date: currentDate))")
          }


      }
}

#Preview {
    ContentView()
}