//
//  ChatServerParser.swift
//  ChatSecureCore
//
//  Created by Boris Rashkov on 13.10.20.
//

import Foundation
import Alamofire

struct AccountChat {
    var usernamerServer: String
}

private enum Constants {
    static let baseURL = "https://admin.tribu.monster/Provisioning_chat/?"
    static let usernameParam = "username"
    static let passwordParam = "password"
    static let defaultServer = "chat.tribu.monster"
}

class ChatServerParser: NSObject {
    
    //MARK: Shared singleton instance
    static let shared: ChatServerParser = ChatServerParser()
    
    //MARK: Private Init
    private override init() {
        
    }
    
    //Used for XML Parsing
    private var serverUsernameFound: Bool = false
    private var chatServer: String? = nil
    
    //XMLParser
    var xmlParser:XMLParser?
    
    //MARK: DispatchGroup variable
    private var networkGroup = DispatchGroup()
    
    //MARK: Determine user's chat server
    public func determineChatServerFor(_ username: String, _ password: String, completionHandler: @escaping (String) -> ()){
        let url = Constants.baseURL
        let params: Parameters = [Constants.passwordParam : password, Constants.usernameParam : username]
        let headers: HTTPHeaders = ["Accept": "application/json"]
        
        DispatchQueue.global().async {
            self.networkGroup.enter()
            Alamofire.request(url, method: .get, parameters: params, encoding: URLEncoding.default, headers: headers).responseString { (response) in
                
                guard let codeStatus = response.response?.statusCode else { return }
                
                switch response.result {
                
                case .success(let msg):
                    
                    let trimmedMsg = msg.stringByReplacingFirstOccurrenceOfString(target: "\n", withString: "")
                    let data = trimmedMsg.data(using: .utf8)
                    self.xmlParser = XMLParser(data: data!)
                    self.xmlParser!.delegate = self
                    self.xmlParser!.parse()
                    
                    self.networkGroup.wait()
                    
                    guard let serverToConnect = self.chatServer else {
                        completionHandler(Constants.defaultServer)
                        return
                    }
                    
                    completionHandler(serverToConnect)
                case .failure(let err):
                    print(err)
                    self.networkGroup.leave()
                    completionHandler(Constants.defaultServer)
                }
                
            }
        }
    }
    
}

//MARK: XMLParserDelegate Methods
extension ChatServerParser: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "username" {
            self.serverUsernameFound = true
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Pares Error --- \(parseError)")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        self.networkGroup.leave()
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if self.serverUsernameFound {
            let serverUsername = string.split(separator: "@")
            
            guard serverUsername.count == 2 else { return }
            
            if let serverAddrString = serverUsername.last {
                self.chatServer = String(serverAddrString)
            }
        }
    }
}

//MARK: String extenstion.
/*
 * Used to remove the unnecessary newlines from the XML
 */
extension String
{
    func stringByReplacingFirstOccurrenceOfString(
            target: String, withString replaceString: String) -> String
    {
        if let range = self.range(of: target) {
            return self.replacingCharacters(in: range, with: replaceString)
        }
        return self
    }
}
