//
//  MapView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import SwiftUI

struct MapView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) var dismiss
    @State private var selectedLocation: MapLocation? = nil
    
    // ✅ БЫЛО: хардкод в самом View → СТАЛО: из модели
    private let locations: [MapLocation] = MapLocation.defaults
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    Image("worldMap")
                        .resizable()
                        .scaledToFit()
                    
                    ForEach(locations) { location in
                        Button {
                            withAnimation(.spring(response: 0.4)) {
                                selectedLocation = location
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(theme.primary, lineWidth: 1)
                                    .frame(width: 30, height: 30)
                                    .opacity(0.5)
                                
                                Circle()
                                    .fill(theme.primary)
                                    .frame(width: 12, height: 12)
                                
                                Image(systemName: location.icon)
                                    .font(.system(size: 8))
                                    .foregroundColor(theme.background)
                            }
                        }
                        .position(
                            x: geo.size.width * location.xPercent / 100,
                            y: geo.size.height * location.yPercent / 100
                        )
                    }
                }
            }
            .padding(16)
            
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(theme.primary)
                            .background(theme.background)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
            
            if let location = selectedLocation {
                ZoomedLocationView(location: location) {
                    withAnimation(.spring(response: 0.4)) {
                        selectedLocation = nil
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
