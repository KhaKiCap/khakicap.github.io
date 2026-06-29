# AthleteVision

영상 촬영 피드백을 통한 선수 관리 iOS 앱

## 주요 기능

- **선수 관리**: 선수 프로필 추가/편집/삭제, 종목·포지션·메모 관리
- **영상 촬영**: 실시간 카메라 촬영, 촬영 시간 표시
- **피드백 시스템**: 영상 재생 중 특정 시점에 피드백 태그 추가
  - 카테고리: 일반 / 잘함 / 개선 / 기술
  - 타임스탬프 기반으로 해당 시점으로 바로 이동
- **데이터 저장**: SwiftData 기반 로컬 저장

## 기술 스택

- **iOS 17+**
- **SwiftUI** - UI 프레임워크
- **SwiftData** - 로컬 데이터 지속성
- **AVFoundation** - 카메라 촬영
- **AVKit** - 영상 재생

## Xcode 프로젝트 설정

1. Xcode에서 **File > New > Project** 선택
2. **iOS > App** 선택
3. 설정:
   - Product Name: `AthleteVision`
   - Bundle Identifier: 원하는 ID (예: `com.yourname.athletevision`)
   - Interface: SwiftUI
   - Language: Swift
4. 생성 후 기본 파일 삭제, 이 레포지토리의 `AthleteVision/` 폴더 내 소스 추가
5. `Info.plist`의 권한 항목을 프로젝트 Info 탭에 추가:
   - Privacy - Camera Usage Description
   - Privacy - Microphone Usage Description
   - Privacy - Photo Library Additions Usage Description

## 파일 구조

```
AthleteVision/
├── AthleteVisionApp.swift       # 앱 진입점, SwiftData 컨테이너
├── ContentView.swift            # 탭 네비게이션
├── Models/
│   ├── Athlete.swift            # 선수 모델 (@Model)
│   ├── VideoSession.swift       # 영상 세션 모델 (@Model)
│   └── FeedbackItem.swift       # 피드백 모델 (@Model + 카테고리 enum)
├── ViewModels/
│   └── CameraManager.swift      # AVFoundation 카메라 관리
└── Views/
    ├── Athletes/
    │   ├── AthleteListView.swift     # 선수 목록
    │   ├── AthleteDetailView.swift   # 선수 상세 + 영상 목록
    │   └── AddAthleteView.swift      # 선수 추가 폼
    └── Video/
        ├── CameraRecordingView.swift # 카메라 촬영 화면
        ├── VideoPlayerView.swift     # 영상 재생 + 피드백 목록
        └── FeedbackEditorView.swift  # 피드백 추가 시트
```
