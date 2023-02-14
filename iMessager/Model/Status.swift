//
//  Status.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/27.
//

import Foundation

enum Status: String, CaseIterable {
    case Available = "オンライン"
    case Busy = "不在"
    case OnTheMove = "移動中"
    case WhileInClass = "授業中"
    case workingOnAProblem = "課題遂行中"
    case workingOnAReport = "レポート作成中"
    case UnderStudy = "研究中"
    case AtWork = "仕事中"
    case WorkingPartTime = "バイト中"
    case TakingABreak = "休憩中"
    case InAMeeting = "会議中"
    case DuringATelephoneCall = "電話中"
    case whileEating = "食事中"
    case Sleeping = "睡眠中"
}


