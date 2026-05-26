import Foundation

final class ReportService1{
    static let shared = ReportService1()
    
    typealias PromptPair = (system: String, user: String)
    
    private let aliyunEndpoint = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    private let aliyunApiKey = "sk-92262754eca4423a9e2e5b84ebe0af5c"
    
    private init() {}
    
    // 核心 API：傳入 prompt，回傳清理後 content 字串（呼叫方自行 decode / 儲存）
    func generateReport(
        prompt: PromptPair,
        model: String = "qwen-plus",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: aliyunEndpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(aliyunApiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": prompt.system],
                ["role": "user", "content": prompt.user]
            ],
            "stream": false,
            "temperature": 0.7,
            "top_p": 0.95,
            "frequency_penalty": 0,
            "presence_penalty": 0,
            "max_tokens": 1500
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unknown response"
                    completion(.failure(NSError(domain: "Failed to parse Aliyun JSON: \(responseString)", code: -1, userInfo: nil)))
                    return
                }
                
                completion(.success(self.normalizeModelContent(content)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // 專用入口：Vocab + Ideas prompt，最後呼叫 generateReport(prompt:)
    func generateVocabIdeasReport(
        from messages: [ChatMessage],
        examText: String,
        userSpeakingTurns: Int,
        totalSpeakingDuringSec: Int,
        partBResponses: [String] = [],
        model: String = "qwen-plus",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = buildVocabIdeasPrompt(
            from: messages,
            examText: examText,
            userSpeakingTurns: userSpeakingTurns,
            totalSpeakingDuringSec: totalSpeakingDuringSec,
            partBResponses: partBResponses
        )
        generateReport(prompt: prompt, model: model, completion: completion)
    }
    
    private func normalizeModelContent(_ content: String) -> String {
        var cleaned = content
        
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }
        
        return cleaned
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func buildVocabIdeasPrompt(
        from messages: [ChatMessage],
        examText: String,
        userSpeakingTurns: Int,
        totalSpeakingDuringSec: Int,
        partBResponses: [String]
    ) -> PromptPair {
        func reportLabel(for message: ChatMessage) -> String {
            message.role == .user ? "user" : (message.speakerName ?? "AI")
        }
        
        let interactionContextText = messages.enumerated().compactMap { index, message -> String? in
            guard message.role == .user else { return nil }
            
            let previousText: String
            if index > 0 {
                let previousMessage = messages[index - 1]
                previousText = "Previous speaker (\(reportLabel(for: previousMessage))): \(previousMessage.content)"
            } else {
                previousText = "Previous speaker: (none)"
            }
            
            return """
            \(previousText)
            user: \(message.content)
            """
        }.joined(separator: "\n\n")
        
        let userOnlyText = messages
            .filter { $0.role == .user }
            .map { "user: \($0.content)" }
            .joined(separator: "\n")
        
        let partBResponseText = partBResponses
            .map { "user_partB: \($0)" }
            .joined(separator: "\n")
        
        let systemPrompt = """
        ## ROLE
        You are an expert HKDSE English Language Examiner.
        Evaluate only the user candidate in this group discussion.

        ## CONTEXT
        - Discussion length: 8 minutes.
        - Candidate to score: user only.

        ## SCORE CALIBRATION
        - Level 2 represents a basic passing performance: limited but understandable language or contribution.
        - Level 4 or above is a relatively strong score and requires clear evidence beyond basic adequacy.
        - Higher scores require both quality and enough evidence: relevant content, development, support, interaction, and control across the user's turns.
        - Limited output should mainly cap Ideas & Organization because there is less evidence of sustained development, task coverage, and interaction.
        - Vocabulary & Language Patterns may differ from Ideas & Organization, but must be based only on the user's actual wording, not the AI speakers' quality.

        ## SCORING CRITERIA (HKDSE Standards)
        ### 1. Vocabulary & Language Patterns (score: 0-7)
        Assessment Focus:
        - Complexity and variety of vocabulary and language patterns.
        - Accuracy and appropriateness of word choice for the topic/tasks.
        - Grammatical control and clarity in spoken communication.
        - Whether language use is mostly generic or truly topic-linked.
        Scoring Criteria:
        - **Level 7**: Impressive range of vocabulary with precision and variation. Uses varied and highly accurate language patterns.
        - **Level 5**: generally appropriate use of vocabulary with precision and variation; complex structures used effectively; near-perfect grammar.
        - **Level 3**: Accuracy over complexity; sufficient vocabulary to convey ideas; simple and compound sentences are mostly accurate; Errors do not usually impede communication.
        - **Level 1**: Limited vocabulary/patterns; relies on simple formulas; frequent errors in basic structures.
        - **Level 0**: Does not produce recognizable words or sequences.

        ### 2. Ideas & Organization (score: 0-7)
        Assessment Focus:
        - Relevance to the exam topic and listed discussion tasks.
        - Quality of idea development (reasons/examples/elaboration).
        - Organization and logical flow of responses.
        - Interaction quality: whether the user responds to others, avoids mere repetition, and contributes original points.
        - Task handling: whether the user addresses different task points meaningfully.
        Scoring Criteria:
        - **Level 7**: Well-developed complex ideas clearly and fluently; excellent development with examples and details; responds effectively to others, sustaining and extending conversational exchanges effortlessly.
        - **Level 5**: Sophisticated ideas; appropriate development with examples; strong ability to link points and move the discussion forward; Responds appropriately to others.
        - **Level 3**: Accuracy over complexity; relevant ideas with some expansion; can use the exam material effectively; Responds to some simple questions.
        - **Level 1**: Brief or repetitive ideas; lacks organization or relies heavily on reading from the material.
        - **Level 0**: Does not produce relevant ideas / material on the topic.

        ## EVALUATION GUIDELINES
        - Use USER ONLY TRANSCRIPT as primary evidence for both scoring categories. Do not reward or penalize based on "ai" speaking's quality.
        - Use INTERACTION CONTEXT only to judge interaction: whether the user responded to others, repeated others, dominated the discussion, or helped move the discussion forward.
        - Topic alignment is mandatory: high scores require clear task-relevant content, not generic agreement.
        - Apply SCORE CALIBRATION before finalizing both scores.
        - Participation & time: Turns = \(userSpeakingTurns), Speaking time = \(totalSpeakingDuringSec) seconds.
          Very low participation or dominating the discussion should reduce Ideas & Organization when it weakens interaction evidence.
        - Penalize Ideas & Organization when ideas are vague, shallow, only listed without development, contradictory, repetitive, off-topic, or unsupported by examples/reasons.
        - Justification must cite specific user quotes.
        - Ignore speech-to-text artifacts (case, punctuation, phonetic typos). Only mention clear spoken linguistic mistakes.

        ## OUTPUT FORMAT
        Return JSON only. Calculate actual scores as INTEGER 0-7 only based on performance.
        {
        "vocabulary_language": { "score": 0, "justification": "String", "strength" : "String", "weakness" : "String", "suggestion" : "String" },
        "ideas_organization": { "score": 0, "justification": "String", "strength" : "String", "weakness" : "String", "suggestion" : "String" }
        }
        """
        
        let userPrompt = """
        【EXAM MATERIAL】
        \(examText)

        【CANDIDATE TO EVALUATE】
        Candidate Name: user
        Turns taken by user: \(userSpeakingTurns)
        Total speaking time by user (seconds): \(totalSpeakingDuringSec)

        【INTERACTION CONTEXT】
        \(interactionContextText.isEmpty ? "No user interaction context available." : interactionContextText)

        【USER ONLY TRANSCRIPT】
        \(userOnlyText.isEmpty ? "user: (no valid speech captured)" : userOnlyText)
        
        【PART B INDIVIDUAL RESPONSE】
        \(partBResponseText.isEmpty ? "user_partB: (no valid response captured)" : partBResponseText)

        ## TASK
        Evaluate the user candidate only. Provide an INTEGER score (0-7) for each category and specific suggestions for improvement.
        Use INTERACTION CONTEXT for interaction judgment and USER ONLY TRANSCRIPT as primary scoring evidence.
        Use PART B INDIVIDUAL RESPONSE as additional evidence for vocabulary range and idea development.

        IMPORTANT: You MUST return ONLY valid JSON. Do not include any other text, markdown headings, or explanations outside the JSON object.
        The "score" field must be an integer in [0-7], no decimals.
        DO NOT use any newlines or line breaks inside the string values. Keep all text within a single line.
        Format your response EXACTLY like this:
        {
          "vocabulary_language": { "score": 0, "justification": "String", "strength": "String", "weakness": "String", "suggestion": "String" },
          "ideas_organization": { "score": 0, "justification": "String", "strength": "String", "weakness": "String", "suggestion": "String" }
        }
        """
        
        return (system: systemPrompt, user: userPrompt)
    }
    
    // 專用入口：Pronunciation & Delivery + Communication Strategies
    func generatePronunCommReport(
        pronunciationData: DSEPronunciationDeliveryData,
        communicationData: DSECommunicationStrategiesData,
        messages: [ChatMessage],
        speakingTurns: Int,
        speakingDurationSeconds: Double,
        model: String = "qwen-plus",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = buildPronunCommPrompt(
            pronunciationData: pronunciationData,
            communicationData: communicationData,
            messages: messages,
            speakingTurns: speakingTurns,
            speakingDurationSeconds: speakingDurationSeconds
        )
        generateReport(prompt: prompt, model: model, completion: completion)
    }
    
    // 專用 prompt builder：Pronunciation/Communication
    func buildPronunCommPrompt(
        pronunciationData: DSEPronunciationDeliveryData,
        communicationData: DSECommunicationStrategiesData,
        messages: [ChatMessage],
        speakingTurns: Int,
        speakingDurationSeconds: Double
    ) -> PromptPair {
        let userOnlyText = messages
            .filter { $0.role == .user }
            .map { "user: \($0.content)" }
            .joined(separator: "\n")
        
        let systemPrompt = """
        ## ROLE
        You are an expert HKDSE English Language Examiner.
        Evaluate only the user's performance in:
        1) Pronunciation & Delivery
        2) Communication Strategies

        ## IMPORTANT TASK SETTING
        - Your job is to explain why the current performance is at this approximate level, based on provided evidence.
        - Focus on diagnostic explanation and actionable improvement advice.

        ## OUTPUT RESTRICTIONS
        - Do NOT output any scores.
        - Do NOT output any numeric values from the input (including percentages, averages, SD, counts, durations, turns, or level numbers).
        - Use qualitative wording only (e.g. "often", "occasionally", "generally stable", "needs more consistency").
        - Keep each field concise, specific, and evidence-based.

        ## HKDSE REFERENCE CRITERIA (FOR INTERNAL JUDGMENT ONLY)
        Use these level anchors only as internal references to calibrate your analysis. Do not output level numbers.

        ### 1) Pronunciation & Delivery
        Assessment Focus:
        - Clarity and comprehensibility of pronunciation.
        - Stress, rhythm, and intonation control.
        - Pace control and smoothness.
        - Whether delivery supports listener understanding and confidence.
        Internal Anchor Guidance:
        - Level 7: Projects the voice appropriately. Speaks fluently and naturally, with very little hesitation using intonation with some sophistication to enhance communication.
        - Level 5: Projects the voice appropriately. Speaks fluently and naturally, with only occasional hesitation, using intonation appropriately to enhance communication. 
        - Level 3: Poor voice projection may cause difficulties for the listener. Less common words may be misunderstood unless supported by contextual meaning. Uses intonation and pacing sufficiently well to be understood by a supportive listener. 
        - Level 1: Poor voice projection is likely to be a problem. Uses intonation appropriately in the most familiar of words and phrases. Hesitant speech is likely to be a problem.
        - Level 0: No usable spoken evidence for meaningful delivery assessment.

        ### 2) Communication Strategies
        Assessment Focus:
        - Turn-taking and interaction management.
        - Responsiveness to others and ability to extend discussion.
        - Use of repair/clarification/follow-up strategies.
        - Non-verbal support indicators (emotion and eye-contact patterns) as interaction evidence.
        Internal Anchor Guidance:
        - Level 7: Uses appropriate body language to display and encourage interest. Uses a full range of strategies skilfully to initiate and maintain interaction and to respond to others.
        - Level 5: Good interaction control; usually responds and develops ideas appropriately. Uses a wide range of strategies to initiate and maintain interaction and to respond to others. 
        - Level 3: Uses some features of body language to support communication. Uses some simple strategies to participate in, and occasionally initiate, interaction mainly by using formulaic expressions.
        - Level 1: Minimal or weak interaction strategy; often passive, repetitive, or disconnected.
        - Level 0: No usable interaction evidence.

        ## OUTPUT FORMAT
        Return JSON only:
        {
          "pronunciation_delivery": { "justification": "String", "strength": "String", "weakness": "String", "suggestion": "String" },
          "communication_strategies": { "justification": "String", "strength": "String", "weakness": "String", "suggestion": "String" }
        }
        """
        
        let userPrompt = """

        ## PRONUNCIATION & DELIVERY INPUT
        Band: \(pronunciationData.band.rawValue)
        Avgerage Volume (dB): \(pronunciationData.avg_volume)
        Standard Deviation of Volume (dB): \(pronunciationData.sd_volume)
        Volume Stability Score: \(pronunciationData.stabilityScore)
        Volume Stability Text: \(pronunciationData.volumeStabilityText)
        Average Pace (WPM): \(pronunciationData.avg_pace)
        Standard Deviation of Pace (WPM): \(pronunciationData.sd_pace)

        ## COMMUNICATION STRATEGIES INPUT
        Band: \(communicationData.band.rawValue)
        Speaking Turns: \(speakingTurns)
        Speaking Duration (seconds): \(speakingDurationSeconds)
        Emotion Percentages: \(communicationData.emotionPercentages.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
        Eye Contact Percentages: \(communicationData.eyeContactPercentages.map { "\($0.key): \($0.value)" }.joined(separator: ", "))

        ## USER ONLY TRANSCRIPT
        \(userOnlyText.isEmpty ? "user: (no valid speech captured)" : userOnlyText)
        """
        
        return (system: systemPrompt, user: userPrompt)
    }
}
