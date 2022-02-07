//
//  ContentView.swift
//  MenuBarPopover
//
//  Created by Zafer Arıcan on 8.07.2020.
//


import SwiftUI

struct ContentView: View {
    @State var isUpdated : Bool = false
    var body: some View {
        VStack{
            Text("Sunset Alert").frame(alignment: .topLeading).padding()
            Image("sunrise_color")
                .resizable(resizingMode: .stretch)
                .frame(width: 100.0, height: 100.0)
            Button("Ok", action: {
                updateStatusBarTitle(title: isUpdated ? "Test" : "TestIt")
                isUpdated.toggle()
            }).padding()
        }        
    }
    func updateStatusBarTitle(title: String){
        AppDelegate.shared.statusBarItem?.button?.title = title
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
