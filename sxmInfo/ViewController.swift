//
//  ViewController.swift
//  sxmInfo
//
//  Created by John Soward on 10/6/17.
//  Copyright © 2017 soward.net. All rights reserved.
//

import Cocoa
import Alamofire
//import AlamofireImage
import SwiftyJSON
import SwiftSoup
import Cocoa
//import CSwiftV

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
//    @IBOutlet weak var mainWindow: NSWindow!
    @IBOutlet weak var channelsTableView: NSTableView!
    
    // Top bar menu item components
    @IBOutlet var theMenu: NSMenu!
    @IBOutlet weak var artistMenu: NSMenuItem!
    @IBOutlet weak var albumMenu: NSMenuItem!
    @IBOutlet weak var composerMenu: NSMenuItem!
    @IBOutlet weak var artMenu: NSMenuItem!
    
    // Info Panel components
    @IBOutlet weak var artist: NSTextField!
    @IBOutlet weak var album: NSTextField!
    @IBOutlet weak var composer: NSTextField!
    @IBOutlet weak var albumImageView: NSImageView!
    @IBOutlet weak var song: NSTextField!
    
    var selectedChannelID: String = "altnation"
    var channelInfo: [Dictionary<String, Any>] = []
    var lastArtistText = ""
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @IBAction func newChannel(_ sender: Any) {
        let item = channelsTableView.selectedRow;
        selectedChannelID = channelInfo[item]["contentID"] as! String;
        print("Selecting new Channel \(item)")
        self.fetchData(self)
    }
    
    @IBAction func doubleClick(_ sender:AnyObject) {
        
        let item = channelsTableView.selectedRow;
        selectedChannelID = channelInfo[item]["contentID"] as! String;
        print ("Selected \(item)")
        self.fetchData(self)
        
    }
    
    // Channel list is generated via javascript in the page shown below. It's noted as a 'legacy' thing, so could break in the future.
    // We can find all the <script> blocks then look for 'rig.AddChannel()' calls, there's one for each channel, then put those values
    // in a Dictionary for later use. The field values are:
    // rig.addChannel(genrekey, channelnumber, BestOfSirius, xmchannelnumber, BestOfXM, contentid, displayname, shortdescription, mediumdescription, vanityurl, channellogo, progtypekey, genretitle, genresortorder);
    // The Logo URL returns a GIF
    // We are mostly interested in the number, name, and contendid. The later is used in the metadata JSON URL to specifiy a specific channel.
    // Vanity URL is just that, a bunch of HTML with a very long description of the channel info ( and a connonical link reference URL  )
    @IBAction func fetchChannelList(_ sender: Any) {
        print("starting fetchChannelList")
        let XMURL="https://www.siriusxm.com/programschedules?intcmp=GN_HEADER_NEW_WhatsON_FindaShoworChannel_ProgramSchedules"
        Alamofire.request(XMURL).responseData { response in
            //print("Request: \(String(describing: response.request))")   // original url request
            //print("Response: \(String(describing: response.response))") // http url response
            //print("Result: \(response.result)")                         // response serialization result
            let docAsString = String(data: response.result.value!, encoding: String.Encoding.utf8)
            do{
                let doc: Document = try SwiftSoup.parse(docAsString!)
                let scripts: Elements = try doc.select("script")
                // Use SwiftSoup to get all the <script> tags, who knows which one will have the calls we want to parse.
                for link: Element in scripts.array() {
                    let data: String = try link.html()
                    // Find rig.addChannel Lines with a regex, capture just the items inside the function call.
                    let pattern = "rig.addChannel\\((.*)\\)";
                    let channelRegex = try! NSRegularExpression(pattern:pattern, options: [])
                    let matches = channelRegex.matches(in: data, range: NSRange(location:0, length:data.count) )
                    for res in matches {
                        // first captured match at index 1, 0 is whole string
                        let matchRange = Range(res.range(at: 1), in: data)
                        let csv = CSwiftV(with: String(data[matchRange!]))
                        //let rows = csv.rows
                        let fields = csv.headers    // Only one line in this CSV 'file', so only headers available.
                        //let keyedRows = csv.keyedRows
                        if (fields[1] == " channelnumber") {
                            continue
                        }
                        
                        var fieldDict = [String: Any]()
                        fieldDict["contentID"]=fields[5]
                        fieldDict["displayName"]=fields[6].replacingOccurrences(of: "\\\"", with: "").replacingOccurrences(of: "\\", with: "")
                        fieldDict["number"] = fields[1]
                        fieldDict["shortDesc"]=fields[7].replacingOccurrences(of: "\\\"", with: "").replacingOccurrences(of: "\\", with: "")
                        fieldDict["mediumDesc"]=fields[8].replacingOccurrences(of: "\\\"", with: "").replacingOccurrences(of: "\\", with: "")
                        //print("fieldDict: \(fieldDict)")
                        fieldDict["logo"]=NSImage(contentsOf: URL(string: "https://www.siriusxm.com/"+fields[10] )!)
                        self.channelInfo.append(fieldDict)
                    }
                    self.channelsTableView.reloadData()
                    
                }
                //self.channelsTableView.reloadData()
                print("ending fetchChannelList, \(self.channelInfo.count) channels loaded")
                
            } catch Exception.Error(let type, let message) {
                print("Message \(message)\nType \(type)")
            } catch {
                print("Error!")
            }
        }
        
        
    }
    
    
    @IBAction func fetchData(_ sender: Any) {
        
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-HH:mm:00"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let myDate = formatter.string(from: Date())
        let songInfoURL="https://www.siriusxm.com/metadata/pdt/en-us/json/channels/"+self.selectedChannelID+"/timestamp/"+myDate
        print("fetchingURL: \(songInfoURL)")
        
        Alamofire.request(songInfoURL).responseData { response in
            
            if ( response.result.value  != nil) {
                let json = JSON( data:response.result.value!)
                if (true) {
                    //print("JSON: \(json)") // serialized json response
                    
                    let artistText = json["channelMetadataResponse"]["metaData"]["currentEvent"]["artists"]["name"].string
                    
                    let songText = json["channelMetadataResponse"]["metaData"]["currentEvent"]["song"]["name"].string
                    
                    let albumText = json["channelMetadataResponse"]["metaData"]["currentEvent"]["song"]["album"]["name"].string
                    
                    let composerText = json["channelMetadataResponse"]["metaData"]["currentEvent"]["song"]["composer"].string
                    
                    let iconURLa = json["channelMetadataResponse"]["metaData"]["currentEvent"]["baseUrl"].string
                    let iconURLb = json["channelMetadataResponse"]["metaData"]["currentEvent"]["song"]["creativeArts"][2]["url"].string
                    
                    if (artistText != nil) {
                        if ( artistText == self.lastArtistText) {
                            return
                        }
                        self.lastArtistText = artistText!
                        self.artist.stringValue = artistText!
                        self.artistMenu.title = artistText!
                    }
                    
                    if (albumText != nil) {
                        self.album.stringValue = albumText!
                        self.albumMenu.title = albumText!
                    } else {
                        self.album.stringValue = "NA"
                    }
                    
                    if ( songText != nil) {
                        self.song.stringValue = songText!
                        self.statusItem.title = songText!
                    } else {
                        self.song.stringValue = "NA"
                    }
                    
                    if ( composerText != nil) {
                        self.composer.stringValue = composerText!
                        self.composerMenu.title = composerText!
                    } else {
                        self.composer.stringValue = "NA"
                    }
                    
                    if ( ( iconURLa != nil ) && ( iconURLb != nil )) {
                        
                        let iconURL = iconURLa!+iconURLb!
                        print(iconURL)
                        if let image = NSImage(contentsOf: URL(string: iconURL)! ) {
                            self.albumImageView.image = image
                            self.albumMenu.image = image
                        }
                    }
                }
            } else {
                print("Null response from server")
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedChannelID="altnation"
        var updateSongTimer: Timer?
        updateSongTimer = Timer.scheduledTimer(timeInterval: 7.0, target: self, selector: #selector(ViewController.fetchData), userInfo: nil, repeats: true)
        if ( updateSongTimer == nil) {
            NSLog("could not start updateSongTimer")
        }
        statusItem.title = "sxmInfo"
        statusItem.menu = theMenu
        
        self.fetchData(self);
        self.fetchChannelList(self)
        
        self.channelsTableView.delegate = self
        self.channelsTableView.dataSource = self
        
    }
    
    override var representedObject: Any? {
        didSet {
            print("representedObject")
            // Update the view, if already loaded.
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        //print ("ChannelInfo Size: \(channelInfo.count)")
        return channelInfo.count
    }
 
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let myCustomView = customTableViewRow()
        myCustomView.thisRow = row
        return myCustomView
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let result:JSTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! JSTableCellView
        if ( channelInfo.count > row) {
            result.chanNameTextField.stringValue = channelInfo[row]["displayName"] as! String
            result.chanDescTextField.stringValue = channelInfo[row]["shortDesc"] as! String
            result.chanDescTextField.toolTip = channelInfo[row]["mediumDesc"] as? String
            result.chanNumberTextField.stringValue = channelInfo[row]["number"] as! String
            //result.chanIDTextField.stringValue = channelInfo[row]["contentID"] as! String
            result.chanImgView.image = channelInfo[row]["logo"] as? NSImage
        }
        return result;
    }
}

