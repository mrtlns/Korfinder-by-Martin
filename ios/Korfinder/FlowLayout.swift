//
//  FlowLayout.swift
//  Korfinder
//
//  Created by martin on 2.10.25.
//
import SwiftUI

struct FlowLayout<Data: RandomAccessCollection, Content: View, ID: Hashable>: View {
    var data: Data
    var id: KeyPath<Data.Element, ID>
    var spacing: CGFloat
    var content: (Data.Element) -> Content

    init(_ data: Data, id: KeyPath<Data.Element, ID>, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data; self.id = id; self.spacing = spacing; self.content = content
    }

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(data, id: id) { item in
                    content(item)
                        .padding(.trailing, spacing)
                        .alignmentGuide(.leading) { d in
                            if abs(width - d.width) > geo.size.width {
                                width = 0; height -= d.height + spacing
                            }
                            let result = width
                            width -= d.width + spacing
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            return result
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}
