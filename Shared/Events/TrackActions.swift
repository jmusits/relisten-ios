//
//  TrackActions.swift
//  Relisten
//
//  Created by Alec Gorge on 5/24/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

public class TrackActions {
    public static func showActionOptions(fromViewController vc: UIViewController, forTrack info: CompleteTrackShowInformation) {
        let duration = info.track.track.duration?.humanize()
        
        let a = UIAlertController(
            title: "\(info.track.track.title) \((duration == nil ? "" : "(\(duration!)" )))",
            message: "\(info.source.display_date) — \(info.artist.name)",
            preferredStyle: .actionSheet
        )
        
        a.addAction(UIAlertAction(title: "Play Now", style: .default, handler: { _ in
            self.play(track: info, fromViewController: vc)
        }))
        
        a.addAction(UIAlertAction(title: "Play Next", style: .default, handler: { _ in
            let ai = info.track.track.toAudioItem(inSource: info.source, fromShow: info.show, byArtist: info.artist)
            PlaybackController.sharedInstance.playbackQueue.insert(ai, at: UInt(PlaybackController.sharedInstance.player.currentIndex) + UInt(1))
        }))
        
        a.addAction(UIAlertAction(title: "Add to End of Queue", style: .default, handler: { _ in
            let ai = info.track.track.toAudioItem(inSource: info.source, fromShow: info.show, byArtist: info.artist)
            PlaybackController.sharedInstance.playbackQueue.append(ai)
        }))
        
        MyLibraryManager.shared.library.diskUsageForTrack(track: info.track.track) { (size) in
            if let s = size {
                a.addAction(UIAlertAction(title: "Remove Downloaded File" + " (\(s.humanizeBytes()))", style: .default, handler: { _ in
                    RelistenDownloadManager.shared.delete(track: info.track.track, saveOffline: true)
                }))
            }
            else {
                a.addAction(UIAlertAction(title: "Make Available Offline", style: .default, handler: { _ in
                    self.download(info.track, inShow: CompleteShowInformation(source: info.source, show: info.show, artist: info.artist))
                }))
            }
            
            a.addAction(UIAlertAction(title: "Share", style: .default, handler: { _ in
            }))
            
            a.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            }))
            
            if PlaybackController.sharedInstance.hasBarBeenAdded {
                PlaybackController.sharedInstance.viewController.present(a, animated: true, completion: nil)
            }
            else {
                vc.present(a, animated: true, completion: nil)
            }
        }
    }
    
    public static func download(_ trackStatus: TrackStatus, inShow: CompleteShowInformation) {
        RelistenDownloadManager.shared.download(track: trackStatus.track)
    }
    
    public static func play(trackAtIndexPath idx: IndexPath, inShow info: CompleteShowInformation, fromViewController vc: UIViewController) {
        play(trackAtIndex: UInt(info.source.flattenedIndex(forIndexPath: idx)), inShow: info, fromViewController: vc)
    }
    
    public static func play(trackAtIndex: UInt, inShow info: ICompleteShowInformation, fromViewController vc: UIViewController) {
        let items = info.source.toAudioItems(inShow: info.show, byArtist: info.artist)
        
        PlaybackController.sharedInstance.playbackQueue.clearAndReplace(with: items)
        
        PlaybackController.sharedInstance.displayMini(on: vc, completion: nil)
        
        PlaybackController.sharedInstance.player.playItem(at: trackAtIndex)
    }
    
    public static func play(track info: CompleteTrackShowInformation, fromViewController vc: UIViewController) {
        var idx: UInt = 0
        for set in info.source.sets {
            for track in set.tracks {
                if track.id == info.track.track.id {
                    break
                }
                
                idx = idx + 1
            }
        }
        
        play(trackAtIndex: idx, inShow: info, fromViewController: vc)
    }
}