//
//  DateFormatter+Extensions.swift
//  project-2-lousalvant
//
//  Created by Lou-Michael Salvant on 9/6/24.
//

import Foundation

extension DateFormatter {
    static var postFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium    // For example, "Sep 8, 2024"
        formatter.timeStyle = .short     // For example, "1:45 PM"
        return formatter
    }()
}
