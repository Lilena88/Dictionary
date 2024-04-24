//
//  String + Extensions.swift
//  Dictionary
//
//  Created by Elena Kim on 4/24/24.
//

import Foundation

extension String {
    var containsCyrillic: Bool {
        return self.range(of: "[а-яА-ЯёЁ]", options: .regularExpression) != nil
    }
}
