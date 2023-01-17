//
//  RMEpisode.swift
//  Rick&Morty
//
//  Created by Dmytro Ivanenko on 02.01.2023.
//

import Foundation

struct RMEpisode: Codable, RMEpisodeDataRender {
    
    let id: Int
    let name: String
    let air_date: String
    let episode: String
    let character: [String]
    let url: String
    let created: String
    
}