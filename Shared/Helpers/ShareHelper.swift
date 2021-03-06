//
//  ShareHelper.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public class ShareHelper {
    public static func url(forTrack track: Track) -> URL {
        let urlText = String(
            format: "https://relisten.net/%@/%@/%@/%@/%@?source=%d",
            track.showInfo.artist.slug,
            track.showInfo.show.yearFromDate,
            track.showInfo.show.monthFromDate,
            track.showInfo.show.dayFromDate,
            track.slug,
            track.showInfo.source.id
        )
        
        return URL(string: urlText)!
    }
    
    public static func url(forSource info: CompleteShowInformation) -> URL {
        let urlText = String(
            format: "https://relisten.net/%@/%@/%@/%@?source=%d",
            info.artist.slug,
            info.show.yearFromDate,
            info.show.monthFromDate,
            info.show.dayFromDate,
            info.source.id
        )
        
        return URL(string: urlText)!
    }
    
    public static func text(forTrack track: Track) -> String {
        let item = SourceTrackAudioItem(track)
        
        var text = item.displayText
        
        if track.showInfo.artist.features.track_durations, let dur = track.duration {
            text += " (\(dur.humanize()))"
        }
        
        text += " • " + item.displaySubtext

        return text
    }
    
    public static func text(forSource info: CompleteShowInformation) -> String {
        var text = String(format: "%@ • %@", info.artist.name, info.show.display_date)
        
        if info.artist.features.track_durations, let dur = info.source.duration {
            text += " (\(dur.humanize()))"
        }
        
        if let v = info.show.correctVenue(withFallback: info.source.venue) {
            text += " • \(v.name), \(v.location)"
        }

        return text
    }
    
    static func viewController(activityItems items: [Any]) -> UIActivityViewController {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
            vc.modalTransitionStyle = .coverVertical
            
            return vc
        }
        
        let vc = VisualActivityViewController(activityItems: items, applicationActivities: nil)
        vc.previewNumberOfLines = 10
        vc.modalTransitionStyle = .coverVertical
        
        return vc
    }
    
    public static func shareViewController(forTrack track: Track) -> UIViewController {
        let items: [Any] = [text(forTrack: track), url(forTrack: track)]
        
        return viewController(activityItems: items)
    }
    
    public static func shareViewController(forSource: CompleteShowInformation) -> UIViewController {
        let items: [Any] = [text(forSource: forSource), url(forSource: forSource)]
        
        return viewController(activityItems: items)
    }
}
