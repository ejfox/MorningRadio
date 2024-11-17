//
//  ScrapDetailView.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/17/24.
//
import SwiftUI
import CoreData
import Foundation

// MARK: - ScrapDetailView
struct ScrapDetailView: View {
    let scrap: Scrap
    let uiImage: UIImage?
    let dismissAction: () -> Void
    
    @State private var showShareSheet: Bool = false
    @State private var isAppearing = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // MARK: - Background Layer
                backgroundColor
                
                // MARK: - Content Layer
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with Percentage-based Top Padding
                        Text(try! AttributedString(markdown: scrap.content))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                            .padding(.top, geometry.size.height * 0.08)  // 8% of screen height
                            .frame(maxWidth: geometry.size.width - 48, alignment: .leading)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // Summary
                        if let summary = scrap.summary {
                            Text(try! AttributedString(markdown: summary))
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundColor(textColor.opacity(0.8))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: geometry.size.width - 48, alignment: .leading)
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 20)
                        }
                        
                        // Metadata
                        if let metadata = scrap.metadata {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Details")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(textColor)
                                    .padding(.top, 16)
                                
                                ForEach(metadata.displayableProperties(), id: \.key) { item in
                                    HStack(alignment: .top) {
                                        Text("\(item.key.capitalized):")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(textColor.opacity(0.7))
                                        Text("\(item.value)")
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundColor(textColor)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: geometry.size.width - 64)
                                }
                            }
                            .padding(.vertical, 16)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 50)
                        }
                        
                        // Bottom spacing for share button
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                }
                .frame(width: geometry.size.width)
                
                // MARK: - Share Button Layer
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .soft)
                            impact.impactOccurred(intensity: 0.7)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showShareSheet = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(textColor)
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                        .offset(y: isAppearing ? 0 : 100)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .sheet(isPresented: $showShareSheet) {
                if let href = scrap.metadata?.href,
                   let url = URL(string: href) {
                    ShareSheet(items: [url])
                } else {
                    ShareSheet(items: [scrap.content])
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
        }
        .onDisappear {
            isAppearing = false
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.impactOccurred()
            withAnimation(.easeInOut(duration: 0.3)) {
                dismissAction()
            }
        }
    }
    
    // Computed properties for dynamic theming
    private var backgroundColor: Color {
        colorScheme == .dark ?
            Color(red: 0.1, green: 0.1, blue: 0.2) :
            Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ?
            .white :
            .black
    }
}
