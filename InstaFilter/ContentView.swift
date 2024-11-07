//
//  ContentView.swift
//  InstaFilter
//
//  Created by Kok on 11/6/24.
//

import PhotosUI
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import StoreKit

struct ContentView: View {
    @Environment(\.requestReview) var requestReview;
    @AppStorage("filterCount") var filterCount = 0;
    
    @State private var showingFilters = false;
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var processedImage: Image?
    @State private var filterIntesity = 0.5;
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone();
    let context = CIContext();
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)
                
                Spacer()
                
                HStack {
                    Text("Intensity");
                    Slider(value: $filterIntesity)
                        .onChange(of: filterIntesity, applyProcessing)
                }
                
                HStack {
                    Button("Change filter", action: changeFilter)
                    Spacer()
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage)) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("InstaFilter")
            .confirmationDialog("Select filter", isPresented: $showingFilters) {
                Button("Crystalize") { setFilter(.crystallize()) }
                Button("Edges") { setFilter(.edges()) }
                Button("Gaussian Blur") { setFilter(.gaussianBlur()) }
                Button("Pixellate") { setFilter(.pixellate()) }
                Button("Sepia tone") { setFilter(.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(.unsharpMask()) }
                Button("Vignette") { setFilter(.vignette()) }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    func changeFilter() {
        showingFilters = true;
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage);
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey);
            applyProcessing();
        }
    }
    
    func applyProcessing() {
        if currentFilter.inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntesity, forKey: kCIInputIntensityKey);
        }
        if currentFilter.inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterIntesity * 200, forKey: kCIInputRadiusKey);
        }
        if currentFilter.inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntesity * 10, forKey: kCIInputScaleKey);
        }
    
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return };
        
        let uiImage = UIImage(cgImage: cgImage);
        self.processedImage = Image(uiImage: uiImage);
    }
    
    @MainActor
    func setFilter(_ filter: CIFilter) {
        self.currentFilter = filter;
        self.loadImage();
        filterCount += 1;
        if filterCount >= 20 {
            requestReview();
        }
    }
}

#Preview {
    ContentView()
}
