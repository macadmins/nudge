//
//  nudgePrefs.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import Foundation

// TODO: use CFPreferences to get mdm/mobileconfig logic and prioritize over json

struct nudgePrefs{
    func decode(data: Data) throws -> jsonPrefs? {
        do {
            let decoder = JSONDecoder()
            let data = try decoder.decode(jsonPrefs.self, from: data)
            return data
        } catch let error {
            print(error)
            return nil
        }
    }

    func loadNudgePrefs() -> jsonPrefs? {
        guard let fileURL = Bundle.main.url(forResource: "example", withExtension: "json") else {
            print("couldn't find the file")
            return nil
        }
        
        do {
            let content = try Data(contentsOf: fileURL)
            let user = try decode(data: content)
            return user

        } catch let error {
            print(error)
            return nil
        }
    }
}

struct jsonPrefs: Codable {
    let button_title_text: String
    let button_sub_titletext: String
    let cut_off_date: String
    let cut_off_date_warning: Int
    let days_between_notifications: Int
    let dismissal_count_threshold: Int
    let logo_dark_path: String
    let logo_light_path: String
    let main_subtitle_text: String
    let main_title_text: String
    let minimum_os_version: String
    let more_info_url: String
    let no_timer: Bool
    let paragraph_text: String
    let paragraph_title_text: String
    let path_to_app: String
    let random_delay: Bool
    let screenshot_path: String
    let timer_day_1: Int
    let timer_day_3: Int
    let timer_elapsed: Int
    let timer_final: Int
    let timer_initial: Int
    let update_minor: Bool
    let update_minor_days: Int
}
