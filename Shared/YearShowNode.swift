//
// Created by Alec Gorge on 5/31/17.
// Copyright (c) 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import AXRatingView

import AsyncDisplayKit
import Observable

public class YearShowCellNode : ASCellNode {
    public let show: Show
    public let artist: SlimArtist?
    public let rank: Int?
    public let vertical: Bool
    
    var disposal = Disposal()
    
    public convenience init(show: Show) {
        self.init(show: show, withRank: nil, verticalLayout: false, showingArtist: nil)
    }
    
    public init(show: Show, withRank: Int?, verticalLayout: Bool, showingArtist: SlimArtist? = nil) {
        self.show = show
        artist = showingArtist
        rank = withRank
        vertical = verticalLayout
        
        if let artist = showingArtist {
            artistNode = ASTextNode(artist.name, textStyle: .caption1, color: AppColors.mutedText)
        }
        else {
            artistNode = nil
        }
        
        showNode = ASTextNode(show.display_date, textStyle: .headline)
        
        var venueText = " \n "
        if let v = show.venue {
            venueText = "\(v.name)\n\(v.location)"
        }
        
        venueNode = ASTextNode(venueText, textStyle: .caption1)
        ratingNode = AXRatingViewNode(value: show.avg_rating / 10.0)
        
        var metaText = "\(show.avg_duration == nil ? "" : show.avg_duration!.humanize())"
        if !verticalLayout {
            metaText += "\n\(show.source_count) recordings"
        }
        
        metaNode = ASTextNode(metaText, textStyle: .caption1, color: nil, alignment: vertical ? nil : NSTextAlignment.right)
        
        if let rank = withRank {
            rankNode = ASTextNode("#\(rank)", textStyle: .headline, color: AppColors.mutedText)
        }
        else {
            rankNode = nil
        }
        
        if show.has_soundboard_source {
            soundboardIndicatorNode = SoundboardIndicatorNode()
        }
        else {
            soundboardIndicatorNode = nil
        }
        
        isAvailableOffline = MyLibraryManager.shared.library.isShowAtLeastPartiallyAvailableOffline(self.show)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        
        if verticalLayout {
            borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
            borderWidth = 1.0
            cornerRadius = 3.0
        }
        else {
            accessoryType = .disclosureIndicator
        }
    }
    
    public let artistNode: ASTextNode?
    public let showNode: ASTextNode
    public let venueNode: ASTextNode
    public let ratingNode: AXRatingViewNode
    public let metaNode: ASTextNode
    
    public let rankNode: ASTextNode?
    public let offlineIndicatorNode = OfflineIndicatorNode()
    public let soundboardIndicatorNode: SoundboardIndicatorNode?
    
    var isAvailableOffline = false
    
    public override func didLoad() {
        super.didLoad()
        
        let library = MyLibraryManager.shared.library
        library.observeOfflineSources
            .observe({ [weak self] _, _ in
                guard let s = self else { return }
                
                if s.isAvailableOffline != library.isShowAtLeastPartiallyAvailableOffline(s.show) {
                    s.isAvailableOffline = !s.isAvailableOffline
                    s.setNeedsLayout()
                }
            })
            .add(to: &disposal)
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        if vertical {
            var verticalStack: [ASLayoutElement] = []
            
            if let art = artistNode {
                verticalStack.append(art)
            }
            
            verticalStack.append(contentsOf: [
                showNode,
                venueNode,
                ratingNode
            ])
            
            var metaStack: [ASLayoutElement] = []

            if isAvailableOffline {
                metaStack.append(offlineIndicatorNode)
            }
            
            if let sbd = soundboardIndicatorNode {
                metaStack.append(sbd)
            }
            
            metaStack.append(metaNode)
            
            let vs = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .start,
                alignItems: .center,
                children: metaStack
            )
            vs.style.minHeight = .init(unit: .points, value: 22.0)
            
            verticalStack.append(vs)
            
            return ASInsetLayoutSpec(
                insets: UIEdgeInsetsMake(12, 12, 12, 12),
                child: ASStackLayoutSpec(
                    direction: .vertical,
                    spacing: 4,
                    justifyContent: .start,
                    alignItems: .start,
                    children: verticalStack
                )
            )
        }
        
        let top = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(showNode, soundboardIndicatorNode, SpacerNode(), ratingNode)
        )
        top.style.alignSelf = .stretch
        
        let bottom = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .spaceBetween,
            alignItems: .baselineFirst,
            children: ArrayNoNils(venueNode, metaNode)
        )
        bottom.style.alignSelf = .stretch
        
        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4.0,
            justifyContent: .start,
            alignItems: .start,
            children: [top, bottom]
        )
        stack.style.alignSelf = .stretch

        let inset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 8),
            child: stack
        )
        inset.style.alignSelf = .stretch
        
        return inset
        
    }
}