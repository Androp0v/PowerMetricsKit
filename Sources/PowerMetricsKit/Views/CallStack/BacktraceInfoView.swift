//
//  BacktraceInfoView.swift
//
//
//  Created by Raúl Montón Pinillos on 10/3/24.
//

import SwiftUI

struct BacktraceInfoView: View {
    
    let backtraceInfo: BacktraceInfo
    
    var imageAddress: String {
        if let addressInImage = backtraceInfo.info?.addressInImage {
            return "0x\(String(format: "%016x", addressInImage))"
        } else {
            return "Unknown"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            
            Text("Address")
                .bold()
            Text(imageAddress)
                .monospaced()
                .padding(.bottom, 8)
            
            Text("Image")
                .bold()
            Text(backtraceInfo.info?.imageName ?? "Unknown")
                .monospaced()
                .padding(.bottom, 8)
            
            Text("Symbol")
                .bold()
            Text(backtraceInfo.info?.symbolName ?? "Unknown")
                .monospaced()
            
            Spacer()
        }
        .padding(.horizontal)
    }
}
