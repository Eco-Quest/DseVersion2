import Foundation
import CryptoKit

struct TranslationResponse: Codable {
    let from: String?
    let to: String?
    let trans_result: [TransResult]?
    let error_code: String?
    let error_msg: String?
}

struct TransResult: Codable {
    let src: String
    let dst: String
}

class BaiduTranslation {
    static let shared = BaiduTranslation()
    
    // AppID 和 密钥
    private let appid = "20241203002218465"
    private let key = "8bLGKmVH3PtmeAa7G3rS"
    
    private func generateSign(appid: String, q: String, salt: String, key: String) -> String {
        let stringToHash = appid + q + salt + key
        let md5 = Insecure.MD5.hash(data: Data(stringToHash.utf8))
        return md5.map { String(format: "%02x", $0) }.joined()
    }
    
    func translateSentence(sentence: String, languageKey: String, completion: @escaping (String?) -> Void) {
        let salt = String(Int(Date().timeIntervalSince1970)) // 使用当前时间戳作为salt
        
        // 构建请求的sign
        let sign = generateSign(appid: appid, q: sentence, salt: salt, key: key)
        
        // 构建请求URL
        let baseURL = "https://api.fanyi.baidu.com/api/trans/vip/translate"
        let urlString = "\(baseURL)?q=\(sentence.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&from=en&to=\(languageKey)&appid=\(appid)&salt=\(salt)&sign=\(sign)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        // 发起HTTP请求
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                // 解析返回的JSON数据
                let json = try JSONDecoder().decode(TranslationResponse.self, from: data)
                DispatchQueue.main.async {
                    if let translatedText = json.trans_result?.first?.dst {
                        completion(translatedText)
                    } else {
                        print("Translation failed or no result. Error code: \(json.error_code ?? "nil")")
                        completion(nil)
                    }
                }
            } catch {
                print("Failed to parse response: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}
