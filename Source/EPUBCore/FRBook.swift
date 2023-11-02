//
//  FRBook.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 09/04/15.
//  Extended by Kevin Jantzer on 12/30/15
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

open class FRBook: NSObject , NSCopying {
    
    var metadata = FRMetadata()
    var spine = FRSpine()
    var smils = FRSmils()
    var version: Double?
    
    public var opfResource: FRResource!
    public var tocResource: FRResource?
    public var uniqueIdentifier: String?
    public var coverImage: FRResource?
    public var name: String?
    public var resources = FRResources()
    public var tableOfContents: [FRTocReference]!
    public var flatTableOfContents: [FRTocReference]!

    override init() {}
    init(metadata: FRMetadata,spine:FRSpine,smils:FRSmils,version:Double?,opfResource:FRResource,
         tocResource:FRResource?,uniqueIdentifier:String?,coverImage:FRResource?,name: String?,
         resources:FRResources,tableOfContents:[FRTocReference],flatTableOfContents: [FRTocReference],
         hasAudio:Bool,title:String?,authorName: String?,duration: String?,activeClass: String, playbackActiveClass: String) {
        self.metadata = metadata
        self.spine = spine
        self.smils = smils
        self.version = version
        self.opfResource = opfResource
        self.tocResource = tocResource
        self.uniqueIdentifier = uniqueIdentifier
        self.coverImage = coverImage
        self.name = name
        self.resources = resources
        self.tableOfContents = tableOfContents
        self.flatTableOfContents = flatTableOfContents
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = FRBook(metadata: metadata, spine: spine, smils: smils, version: version, opfResource: opfResource, tocResource: tocResource, uniqueIdentifier: uniqueIdentifier, coverImage: coverImage, name: name, resources: resources, tableOfContents: tableOfContents, flatTableOfContents: flatTableOfContents, hasAudio: hasAudio, title: title, authorName: authorName, duration: duration, activeClass: activeClass, playbackActiveClass: playbackActiveClass)
        return copy
    }
    
    var hasAudio: Bool {
        return smils.smils.count > 0
    }

    var title: String? {
        return metadata.titles.first
    }

    var authorName: String? {
        return metadata.creators.first?.name
    }

    // MARK: - Media Overlay Metadata
    // http://www.idpf.org/epub/301/spec/epub-mediaoverlays.html#sec-package-metadata

    var duration: String? {
        return metadata.find(byProperty: "media:duration")?.value
    }

    var activeClass: String {
        guard let className = metadata.find(byProperty: "media:active-class")?.value else {
            return "epub-media-overlay-active"
        }
        return className
    }

    var playbackActiveClass: String {
        guard let className = metadata.find(byProperty: "media:playback-active-class")?.value else {
            return "epub-media-overlay-playing"
        }
        return className
    }

    // MARK: - Media Overlay (SMIL) retrieval

    /**
     Get Smil File from a resource (if it has a media-overlay)
     */
    func smilFileForResource(_ resource: FRResource?) -> FRSmilFile? {
        guard let resource = resource, let mediaOverlay = resource.mediaOverlay else { return nil }

        // lookup the smile resource to get info about the file
        guard let smilResource = resources.findById(mediaOverlay) else { return nil }

        // use the resource to get the file
        return smils.findByHref(smilResource.href)
    }

    func smilFile(forHref href: String) -> FRSmilFile? {
        return smilFileForResource(resources.findByHref(href))
    }

    func smilFile(forId ID: String) -> FRSmilFile? {
        return smilFileForResource(resources.findById(ID))
    }
    
    // @NOTE: should "#" be automatically prefixed with the ID?
    func duration(for ID: String) -> String? {
        return metadata.find(byProperty: "media:duration", refinedBy: ID)?.value
    }
    
}

struct SearchData {
    var content:String
    var html:String
    var href:String
    var fullHref:String
    var range:NSRange
    var resource: FRResource
    var page:Int
    
    init(content: String, html:String, href: String, fullHref:String, range:NSRange, resource:FRResource, page:Int) {
        self.content = content
        self.html = html
        self.href = href
        self.fullHref = fullHref
        self.range = range
        self.resource = resource
        self.page = page
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
    subscript(range: Range<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    subscript(range: ClosedRange<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    subscript(range: PartialRangeFrom<Int>) -> SubSequence { self[index(startIndex, offsetBy: range.lowerBound)...] }
    subscript(range: PartialRangeThrough<Int>) -> SubSequence { self[...index(startIndex, offsetBy: range.upperBound)] }
    subscript(range: PartialRangeUpTo<Int>) -> SubSequence { self[..<index(startIndex, offsetBy: range.upperBound)] }
}
extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }
}
