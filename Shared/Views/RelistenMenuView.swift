//
//  RelistenMenuView.swift
//  Relisten
//
//  Created by Alec Gorge on 3/7/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit
import ActionKit

public enum RelistenMenuCategory: Int {
    case Everything
    case Discover
    case Recent
    case MyShows
}

public enum RelistenMenuItem: Int {
    case EverythingYears
    case EverythingSongs
    case EverythingVenues
    case EverythingTours
    
    case DiscoverTop
    case DiscoverRandom
    case DiscoverTodayInHistory
    
    case RecentlyPlayed
    case RecentlyPerformed
    case RecentlyUpdated
    
    case MyShowsLibrary
    case MyShowsPlaylists
    case MyShowsDownloaded
}

public class RelistenMenuView : UIView {
    public let artist: ArtistWithCounts
    public weak var viewController: UIViewController?
    
    private let size_MenuLineSpacing: CGFloat = 16.0 as CGFloat
    private let size_ButtonVerticalPadding: CGFloat = 8.0 as CGFloat
    private let size_ButtonHorizontalPadding: CGFloat = 16.0 as CGFloat
    
    private var size_ReferenceButton: UIButton!
    
    private let menuCategories: [RelistenMenuCategory]
    private let menu: [[RelistenMenuItem]]
    
    public required init(artist: ArtistWithCounts, inViewController vc: UIViewController) {
        self.artist = artist
        self.viewController = vc
        
        var everything: [RelistenMenuItem] = []
        var discover: [RelistenMenuItem] = []
        let my: [RelistenMenuItem] = [.MyShowsLibrary, .RecentlyPlayed, /* .MyShowsPlaylists, */ .MyShowsDownloaded]
        
        if artist.features.years { everything.append(.EverythingYears) }
        if artist.features.songs { everything.append(.EverythingSongs) }
        if artist.features.per_show_venues || artist.features.per_source_venues {
            everything.append(.EverythingVenues)
        }
        
        if artist.features.ratings {
            discover.append(.DiscoverTop)
        }
        
        discover.append(.DiscoverRandom)
        discover.append(.DiscoverTodayInHistory)

        menuCategories = [.Everything, .Discover, .Recent, .MyShows]
        
        menu = [
            everything,
            discover,
            [ .RecentlyPerformed, .RecentlyUpdated ],
            my
        ]
        
        super.init(frame: .zero)
        
        size_ReferenceButton = menuButton(forTitle: "Test")
        
        buildSubviews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let combinedButtonHeight = size_ReferenceButton.bounds.height * CGFloat(menu.count)
        let combinedSpacingHeight = (CGFloat(menu.count - 1) * size_MenuLineSpacing)
        
        return CGSize(width: max(size.width, 320), height: combinedButtonHeight + combinedSpacingHeight)
    }
    
    public override func layoutSubviews() {
        layoutSubviews(forWidth: bounds.size.width)
    }
    
    private func layoutSubviews(forWidth width: CGFloat) {
        for (idx, categoryButton) in uiButtons.enumerated() {
            var categoryButtonFrame = categoryButton.frame
            categoryButtonFrame.origin.y = CGFloat(idx) * categoryButtonFrame.size.height + CGFloat(idx) * size_MenuLineSpacing
            categoryButton.frame = categoryButtonFrame
            
            let containerFrame = CGRect(x: -width * 2,
                                        y: categoryButton.frame.origin.y,
                                        width: width * 2,
                                        height: categoryButton.frame.size.height)
            
            uiContainers[idx].frame = containerFrame
            
            let subItems = uiSubmenuButtons[idx]
            let submenuButtonWidth = width / CGFloat(subItems.count)
            
            for (sub_idx, subButton) in subItems.enumerated() {
                subButton.frame = CGRect(x: width + CGFloat(sub_idx) * submenuButtonWidth,
                                         y: 0,
                                         width: submenuButtonWidth,
                                         height: categoryButton.frame.size.height)
            }
        }
    }
    
    private var uiButtons: [UIButton] = []
    private var uiContainers: [UIView] = []
    private var uiSubmenuButtons: [[UIButton]] = []
    
    public func buildSubviews() {
        uiButtons = menuCategories.map { menuButton(forButton: $0) }
        
        for (idx, categoryButton) in uiButtons.enumerated() {
            categoryButton.addTarget(self, action: #selector(menuItemTapped(_:)), for: .touchUpInside)

            let subItems = menu[idx]

            let container = UIView(frame: .zero)
            
            container.tag = createTag(forButton: menuCategories[idx])
            container.backgroundColor = AppColors.primary
            
            var thisSubmenuButtons: [UIButton] = []
            
            for subMenuItem in subItems {
                let subButton = menuButton(forSubmenuButton: subMenuItem)
                subButton.addTarget(self, action: #selector(submenuItemTapped(_:)), for: .touchUpInside)
                
                container.addSubview(subButton)
                
                thisSubmenuButtons.append(subButton)
            }
            
            uiContainers.append(container)
            
            uiSubmenuButtons.append(thisSubmenuButtons)
            
            addSubview(container)
            addSubview(categoryButton)
        }
        
        layoutSubviews(forWidth: 320)
    }
    
    private func pushViewController(_ vc : UIViewController, animated : Bool = true) {
        self.viewController?.navigationController?.pushViewController(vc, animated: animated)
    }
    
    @objc public func submenuItemTapped(_ sender: UIButton?) {
        guard let btn = sender, let item = decodeMenuItem(forTag: btn.tag) else {
            return
        }
        
        switch item {
        case .EverythingYears:
            self.pushViewController(YearsViewController(artist: artist))

        case .EverythingSongs:
            self.pushViewController(SongsViewController(artist: artist))
            
        case .EverythingVenues:
            self.pushViewController(VenuesViewController(artist: artist))
            
        case .EverythingTours:
            break
        case .DiscoverTop:
            self.pushViewController(TopShowsViewController(artist: artist))
            
        case .DiscoverRandom:
            let sourcesViewController = SourcesViewController(artist: artist)
            sourcesViewController.presentIfNecessary(navigationController: viewController?.navigationController)
            
        case .DiscoverTodayInHistory:
            self.pushViewController(TodayInHistoryViewController(artist: artist))
            
        case .RecentlyPlayed:
            self.pushViewController(RecentlyPlayedTabViewController(artist))
        
        case .RecentlyPerformed:
            self.pushViewController(RecentlyPerformedViewController(artist: artist))
            
        case .RecentlyUpdated:
            self.pushViewController(RecentlyAddedViewController(artist: artist))
            
        case .MyShowsLibrary:
            self.pushViewController(MyLibraryTabViewController(artist))

        case .MyShowsPlaylists:
            break
        case .MyShowsDownloaded:
            self.pushViewController(DownloadedTabViewController(artist))
        }
        
    }
    
    @objc public func menuItemTapped(_ sender: UIButton?) {
        guard let btn = sender, let _ = decodeCategory(forTag: btn.tag) else {
            return
        }
        
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.5,
                       options: [ .curveEaseOut ],
                       animations: {
                        for container in self.uiContainers {
                            var f = container.frame
                            
                            if container.tag == btn.tag {
                                f.origin.x = -self.bounds.width
                            }
                            else {
                                f.origin.x = -self.bounds.width * 2
                            }
                            
                            container.frame = f
                        }
                        
                        for button in self.uiButtons {
                            var f = button.frame
                            
                            if button == btn {
                                f.origin.x = self.bounds.width
                            }
                            else {
                                f.origin.x = 0
                            }
                            
                            button.frame = f
                        }
        }, completion: nil)
    }
    
    public func title(forButton: RelistenMenuCategory) -> String {
        switch forButton {
        case .Discover: return "discover"
        case .Everything: return "everything"
        case .Recent: return "recent"
        case .MyShows: return "my shows"
        }
    }

    public func title(forSubmenuButton: RelistenMenuItem) -> String {
        switch forSubmenuButton {
        case .EverythingYears: return "years"
        case .EverythingSongs: return "songs"
        case .EverythingVenues: return "venues"
        case .EverythingTours: return "tours"
            
        case .DiscoverTop: return "top"
        case .DiscoverRandom: return "random"
        case .DiscoverTodayInHistory: return "today in history"

        case .RecentlyPerformed: return "performed"
        case .RecentlyUpdated: return "updated"
            
        case .MyShowsLibrary: return "my favorites"
        case .RecentlyPlayed: return "my recents"
        case .MyShowsPlaylists: return "playlists"
        case .MyShowsDownloaded: return "downloaded"
        }
    }
    
    public func menuButton(forTitle: String, withTag: Int = -1, top: Bool = false) -> UIButton {
        let button = UIButton(type: .custom)
        
        button.setTitle(forTitle + (top ? " ›" : ""), for: .normal)
        button.accessibilityLabel = forTitle
        button.tag = withTag
        
        button.backgroundColor = AppColors.primary
        button.setTitleColor(AppColors.textOnPrimary, for: .normal)
        
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
            .font(
                scaledBy: top ? 1.1 : 1.0,
                withDifferentWeight: top ? .Heavy : .Semibold
            )
        button.sizeToFit()
        
        button.frame = CGRect(
            x: 0, y: 0,
            width: button.frame.width + size_ButtonHorizontalPadding * 2,
            height: button.frame.height + size_ButtonVerticalPadding * 2
        )
        
        return button
    }
}

extension RelistenMenuView {
    public func createTag(forButton: RelistenMenuCategory) -> Int {
        return forButton.rawValue + 4000
    }
    
    public func decodeCategory(forTag: Int) -> RelistenMenuCategory? {
        return RelistenMenuCategory(rawValue: forTag - 4000)
    }
    
    public func createTag(forSubmenuButton: RelistenMenuItem) -> Int {
        return forSubmenuButton.rawValue + 1000
    }
    
    public func decodeMenuItem(forTag: Int) -> RelistenMenuItem? {
        return RelistenMenuItem(rawValue: forTag - 1000)
    }
    
    public func menuButton(forButton: RelistenMenuCategory) -> UIButton {
        return menuButton(forTitle: title(forButton: forButton), withTag: createTag(forButton: forButton), top: true)
    }
    
    public func menuButton(forSubmenuButton: RelistenMenuItem) -> UIButton {
        return menuButton(forTitle: title(forSubmenuButton: forSubmenuButton), withTag: createTag(forSubmenuButton: forSubmenuButton))
    }
}
