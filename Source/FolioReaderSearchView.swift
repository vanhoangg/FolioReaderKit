//
//  FolioReaderSearchView.swift
//  FolioReaderKit
//
//  Created by Long Vu on 01/11/2023.
//

import UIKit
import Foundation

class FolioReaderSearchView: UIViewController, UITableViewDelegate, UITableViewDataSource , UISearchBarDelegate {
    
    var book: FRBook
    var readerConfig: FolioReaderConfig
    var folioReader: FolioReader
    private let kReuseIdentifier = "folioReaderSearchCell"
    var data:[SearchData] = []
    lazy var searchBar = UISearchBar(frame: CGRect.zero)
    private var tableView: UITableView!
    
    lazy var background = self.folioReader.isNight(self.readerConfig.nightModeBackground, self.readerConfig.dayModeBackground)
    var searchWord:String?
    var stopSearch:Bool = false
    
    var completedSearch:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setCloseButton(withConfiguration: self.readerConfig)
        configureNavBar()
        view.backgroundColor = background
        
        searchBar.placeholder = self.readerConfig.localizedSearchContent
        searchBar.delegate = self
        navigationItem.titleView = searchBar
        
        let titleAttrs = [NSAttributedString.Key.foregroundColor: self.readerConfig.tintColor]
        let share = UIBarButtonItem(title: self.readerConfig.localizedSearch, style: .plain, target: self, action: #selector(searchContent(_:)))
        share.setTitleTextAttributes(titleAttrs, for: UIControl.State())
        navigationItem.rightBarButtonItem = share

        // Do any additional setup after loading the view.
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        tableView.backgroundColor = background
        tableView.bounces = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: kReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(tableView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification , object:nil)
    }
    
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if searchWord != nil {
            if searchWord?.trim() != "" {
                self.data.removeAll()
                print("Start Searching")
                self.tableView.reloadData()
                self.tableView.showActivityIndicator()
                if self.searchBar.text != nil {
                    if self.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        self.completedSearch = false
                        self.stopSearch = false
                        self.bookSearchConntent(content: self.searchBar.text!)
                    }
                    else {
                        self.tableView.hideActivityIndicator()
                    }
                }
                else {
                    self.tableView.hideActivityIndicator()
                }
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.stopSearch = true
        var bodyHtmls = (self.data[indexPath.row].fullHref as NSString)
        let searchTagId = "search"//青色
        let tag = "<search style=\"background-color:#ddd;\"><span id=\"\(searchTagId)\">\(self.data[indexPath.row].html)</span></search>"
        bodyHtmls = bodyHtmls.replacingOccurrences(of: self.data[indexPath.row].html, with: tag) as NSString
        let resource = self.data[indexPath.row].resource
        openSearchFromPage(bodyHtmls: bodyHtmls, resource: resource,page: self.data[indexPath.row].page)
    }
    
    func openSearchFromPage(bodyHtmls:NSString, resource: FRResource, page:Int) {
        self.folioReader.readerCenter?.currentPage?.pageNumber = page
        self.folioReader.readerCenter?.currentPage?.webView?.js("getHTML()") { value in
            var html = value
            html! = html!.replacingOccurrences(of: "<body>(.|[\n])*</body>", with: bodyHtmls as String, options: .regularExpression, range: nil)
            self.folioReader.readerCenter?.currentPage?.webView?.loadHTMLString(html! as String, baseURL: NSURL(fileURLWithPath: (resource.fullHref as NSString).deletingLastPathComponent) as URL)
            self.dismiss {
                self.folioReader.readerCenter?.currentPage?.webView?.js("jumpToSearchId(\("search"))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.folioReader.readerCenter?.updateCurrentPage()
                })
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       let lastSectionIndex = tableView.numberOfSections - 1
       let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1
       if indexPath.section ==  lastSectionIndex && indexPath.row == lastRowIndex {
           if !completedSearch {
               let spinner = UIActivityIndicatorView(style: .gray)
               spinner.startAnimating()
               spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(44))

               self.tableView.tableFooterView = spinner
               self.tableView.tableFooterView?.isHidden = false
           }
           else {
               self.tableView.tableFooterView?.isHidden = true
           }
       }
   }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = CustomCell(frame: CGRectMake(0, 0, self.view.frame.width, 40))
        cell.backgroundColor = background
        cell.cellLabel.text = data[indexPath.row].content
        cell.cellLabel.numberOfLines = 2
        return cell
    }
    
    @objc func searchContent(_ sender: UIBarButtonItem) {
        search()
    }
    
    func search() {
        self.searchWord = self.searchBar.text
        self.searchBar.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search()
    }
    
    @objc func dismissKeyboard() {
        searchBar.endEditing(true)
    }
    
    init(readerConfig: FolioReaderConfig, folioReader: FolioReader, book: FRBook) {
        self.folioReader = folioReader
        self.book = book
        self.readerConfig = readerConfig
        super.init(nibName: nil, bundle: Bundle.frameworkBundle())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func configureNavBar() {
        let navBackground = self.folioReader.isNight(self.readerConfig.nightModeNavBackground, self.readerConfig.daysModeNavBackground)
        let tintColor = self.readerConfig.tintColor
        let navText = self.folioReader.isNight(UIColor.white, UIColor.black)
        let font = UIFont(name: "Avenir-Light", size: 17)!
        setTranslucentNavigation(color: navBackground, tintColor: tintColor, titleColor: navText, andFont: font)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FolioReaderSearchView {
    
    func bookSearchConntent(content:String) {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.folioReader.readerCenter == nil {
                self.tableView.hideActivityIndicator()
                return
            }
            self.data.removeAll()
            var lastAdded:Int = 0
            for j in 0..<self.folioReader.readerCenter!.totalPages {
                if self.stopSearch {
                    self.stopSearch = false
                    break
                }
                let indexPath = NSIndexPath(row: j, section: 0)
                let value = self.book.spine.spineReferences[indexPath.row]
                if let html = try? String(contentsOfFile: value.resource.fullHref, encoding: String.Encoding.utf8) {
                    let htmlStr = html as NSString
                    if htmlStr.contains(content) {
                        var range: NSRange = htmlStr.range(of: content)
                        whileLoop:
                        while true {
                            if range.location == NSNotFound {
                                DispatchQueue.main.async {
                                    self.completedSearch = true
                                    self.tableView.hideActivityIndicator()
                                    self.tableView.reloadData()
                                }
                                break whileLoop
                            }
                            else {
                                if self.stopSearch {
                                    self.stopSearch = false
                                    break
                                }
                                var firstIndex:Int? = nil
                                var lastIndex:Int? = nil
                                if range.location <= html.count-1 {
                                    innerLoop:
                                    for i in (0...range.location).reversed() {
                                        if html[i] == ">" {
                                            firstIndex = i+1
                                            break innerLoop
                                        }
                                        else if html[i] == "." {
                                            firstIndex = i+1
                                            break innerLoop
                                        }
                                        else if html[i] == "!" {
                                            firstIndex = i+1
                                            break innerLoop
                                        }
                                        else if html[i] == "?" {
                                            firstIndex = i+1
                                            break innerLoop
                                        }
                                        else if i == 0 {
                                            firstIndex = i
                                            break innerLoop
                                        }
                                    }
                                    innerLoop:
                                    for i in (range.location...html.count-1) {
                                        if html[i] == "." {
                                            lastIndex = i
                                            break innerLoop
                                        }
                                        else if html[i] == "?" {
                                            lastIndex = i
                                            break innerLoop
                                        }
                                        else if html[i] == "!" {
                                            lastIndex = i
                                            break innerLoop
                                        }
                                        else if html[i] == "<" {
                                            if i+2 <= html.count-1 {
                                                if html[i+1] == "b" && html[i+2] == "r"{
                                                    lastIndex = i-1
                                                    break innerLoop
                                                }
                                                else if html[i+1] == "/" && html[i+2] == "p"{
                                                    lastIndex = i-1
                                                    break innerLoop
                                                }
                                            }
                                        }
                                        else if i == html.count-1 {
                                            lastIndex = i
                                            break innerLoop
                                        }
                                    }
                                    if firstIndex != nil && lastIndex != nil {
                                        let string = html[firstIndex!..<(lastIndex!+1)].trim()
                                        if string != "" {
                                            let content = string.htmlToString
                                            if content != "" {
                                                let myRange = NSRange(location: firstIndex!, length: content.count)
                                                let total = self.data.count
                                                self.data.appendDistinct(contentsOf: [SearchData(content: content ,html: string ,href: value.resource.href, fullHref: html, range: myRange
                                                                                            , resource: value.resource, page: j)], where: { (data1, data2) -> Bool in
                                                    return data1.content != data2.content
                                                })
                                                if total != self.data.count && self.data.count - lastAdded >= 15 {
                                                    lastAdded = self.data.count
                                                    DispatchQueue.main.async {
                                                        self.tableView.hideActivityIndicator()
                                                        self.tableView.reloadData()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                let searchRange = NSMakeRange(range.location + range.length, htmlStr.length - range.length - range.location)
                                let options: NSString.CompareOptions = [
                                    .diacriticInsensitive,
                                    .caseInsensitive,]
                                range = htmlStr.range(of: content, options: options, range: searchRange)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension UITableView {
    func showActivityIndicator() {
        DispatchQueue.main.async {
            let activityView = UIActivityIndicatorView(style: .gray)
            self.backgroundView = activityView
            activityView.startAnimating()
        }
    }

    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.backgroundView = nil
        }
    }
}
extension String {
    var htmlToAttributedString: NSAttributedString? {
        return Data(utf8).htmlToAttributedString
    }

    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

extension Data {
    var htmlToAttributedString: NSAttributedString? {
        // Converts html to a formatted string.
        do {
            return try NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print("error:", error)
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

extension Array{
    public mutating func appendDistinct<S>(contentsOf newElements: S, where condition:@escaping (Element, Element) -> Bool) where S : Sequence, Element == S.Element {
      newElements.forEach { (item) in
        if !(self.contains(where: { (selfItem) -> Bool in
            return !condition(selfItem, item)
        })) {
            self.append(item)
        }
    }
  }
}

class CustomCell: UITableViewCell {
    var cellLabel: PaddingLabel!

    init(frame: CGRect) {
        super.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "folioReaderSearchCell")
        cellLabel = PaddingLabel(frame: CGRectMake(0, 0 , frame.width, frame.height))
        cellLabel.textColor = UIColor.black
        cellLabel.font = UIFont.systemFont(ofSize: 12)
        addSubview(cellLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
   }
}

class PaddingLabel: UILabel {

   @IBInspectable var topInset: CGFloat = 5.0
   @IBInspectable var bottomInset: CGFloat = 5.0
   @IBInspectable var leftInset: CGFloat = 5.0
   @IBInspectable var rightInset: CGFloat = 5.0

   override func drawText(in rect: CGRect) {
      let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
       super.drawText(in: rect.inset(by: insets))
   }

   override var intrinsicContentSize: CGSize {
      get {
         var contentSize = super.intrinsicContentSize
         contentSize.height += topInset + bottomInset
         contentSize.width += leftInset + rightInset
         return contentSize
      }
   }
}

class RegExp {
    let internalRegexp: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        self.internalRegexp = try! NSRegularExpression( pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
    }
    
    func isMatch(input: String) -> Bool {
        let matches = self.internalRegexp.matches( in: input, options: [], range:NSMakeRange(0, input.characters.count) )
        return matches.count > 0
    }
    
    func matches(input: String) -> [NSTextCheckingResult]? {
        if self.isMatch(input: input) {   //マッチがあるなら
            let matches = self.internalRegexp.matches( in: input, options: [], range:NSMakeRange(0, input.characters.count) )
            return matches
        }
        return nil
    }
}
