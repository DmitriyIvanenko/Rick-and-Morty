//
//  RMSettingsView.swift
//  Rick&Morty
//
//  Created by Dmytro Ivanenko on 23.01.2023.
//

import SwiftUI

struct RMSettingsView: View {
    let viewModel: RMSettingsViewViewModel
    
    init(viewModel: RMSettingsViewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        List(viewModel.cellViewModels) { viewModel in
            HStack {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color.white)
                        .padding(10)
                        .background(Color(viewModel.iconContainerColor))
                        .cornerRadius(6)
                }
                Text(viewModel.title)
                    .padding(.leading, 10)
                
                Spacer()
            }
            .padding(.bottom, 8)
            .onTapGesture {
                viewModel.onTapHandler(viewModel.type)
            }
        }
    }
}

struct RMSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        RMSettingsView(viewModel: .init(
            cellViewModels: RMSettingsOption.allCases.compactMap({
                return RMSettingsCellViewModel(type: $0) { option in
                    
                }
            })
        )
        )}
}
                       
