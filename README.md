# AirTranslate

AirTranslate는 Mac에서 재생되는 소리를 실시간으로 기록하고 번역하는 SwiftPM 기반 macOS 앱입니다. AirPods Pro 같은 출력 장치에서 들리는 Mac 재생음을 대상으로 하며, 외부 마이크가 아니라 ScreenCaptureKit의 시스템 오디오 캡처를 사용합니다.

## 한 줄 요약

Mac에서 영상, 회의, 강의 같은 오디오를 재생하면 AirTranslate가 원문을 계속 기록하고, 오른쪽에는 번역을 함께 보여주며, 필요하면 번역 음성까지 읽어 줍니다.

현재 앱 버전은 `1.1.0`입니다.

## Privacy-first by design

AirTranslate는 회의, 강의, 영상처럼 민감할 수 있는 소리를 다루기 때문에 처음부터 로컬 중심으로 설계했습니다.

- 자체 서버, 계정, 로그인, API 키가 없습니다.
- 앱 코드에는 오디오나 기록을 외부 서비스로 업로드하는 네트워크 클라이언트가 없습니다.
- 광고, 분석 SDK, 추적 SDK, 원격 텔레메트리를 포함하지 않습니다.
- 저장된 기록은 사용자 Mac의 Application Support 폴더에 일반 텍스트 파일로만 보관됩니다.
- 설정 값은 macOS `UserDefaults`에 저장되며, 별도 클라우드 동기화 계층을 만들지 않습니다.
- 외부 마이크 입력이 아니라 Mac에서 재생 중인 시스템 오디오만 대상으로 합니다.

전사와 번역은 Apple Speech, Apple Translation, ScreenCaptureKit 같은 macOS 시스템 프레임워크를 사용합니다. Speech/Translation 언어 자산은 macOS가 관리하며, 필요한 언어 모델을 Apple 서버에서 다운로드하거나 시스템 차원에서 갱신할 수 있습니다. AirTranslate 자체가 별도의 백엔드로 오디오, 전사문, 번역문을 보내는 구조는 아닙니다.

필요한 권한도 기능에 직접 연결된 것만 요청합니다. 시스템 오디오 캡처를 위한 화면 기록/시스템 오디오 녹음 권한, 전사를 위한 음성 인식 권한이 전부이며, 연락처, 캘린더, 사진, 위치, 전체 디스크 접근, 브라우저 데이터 같은 권한은 요구하지 않습니다.

## 주요 기능

- Mac 시스템 오디오 실시간 캡처
- Apple Speech 기반 실시간 기록
- Apple Translation 기반 실시간 번역
- 자체 서버 없는 로컬 중심 처리
- 광고, 분석 SDK, 원격 텔레메트리 없음
- 사용자가 직접 선택하는 원문/번역 언어
- macOS 선호 언어에 맞춘 한국어/영어 UI 자동 표시
- 원문과 번역을 나란히 보여주는 메모형 작업 공간
- 기록 내용이 사라지지 않는 누적 표시
- 현재 세션을 정지 후에도 확인할 수 있는 기록 화면
- 원문/번역 패널별 내부 스크롤과 긴 기록용 지연 렌더링
- 위쪽 기록을 읽을 때만 나타나는 부드러운 페이드 마스크
- 원문/번역 패널 복사 버튼과 복사 완료 피드백
- 저장된 기록 편집창의 원문/번역별 Apple Intelligence 글쓰기 도구 버튼
- 긴 침묵 구간에서 문맥을 유지한 문단 정리
- 문단 전환 시 2중 개행으로 읽기 편한 정리
- 개행 정리나 설정 변경 중에도 이미 표시된 실시간 전사/번역이 다시 붙지 않도록 하는 중복 방지
- 옵션형 기록 다듬기: macOS 맞춤법 후보 기반의 보수적 단어 교정
- 실시간 기록 일시정지/재개
- 정지 시 현재 기록 저장, 다음 시작 시 새 기록 화면으로 전환
- 높이를 줄인 아이콘 중심 상단 컨트롤 바
- 진행 중 데시벨에 반응하는 중앙 오디오 waveform 미터
- 시작/정지, 일시정지, 플로팅 자막 버튼의 hover/pressed/클릭 완료 피드백
- 자동 저장된 기록 확인, 수정, 삭제
- 날짜와 내용 기반의 일반 텍스트 자동 저장
- `원문 + 번역` 저장 시 원문과 번역을 별도 `.txt` 파일로 보관하고 저장소 UI에서는 하나의 묶음으로 표시
- 마지막으로 선택한 언어, 모델, 출력 옵션 재실행 시 복원
- 상태바 메뉴와 플로팅 자막 창
- 플로팅 자막 표시 모드: 원문, 원문 + 번역, 번역
- 플로팅 자막 글자 크기와 표시 줄 수 설정
- 플로팅 자막 위치 드래그 이동
- 선택적 번역 음성 출력
- 번역 음성 출력 중 원문 소리 비중 완화
- 중복 문장 음성 출력 방지
- macOS Dock에 맞춘 둥근 앱 아이콘과 제품 소개 페이지

## 현재 동작

앱을 시작하면 선택한 원문 언어로 Mac 시스템 오디오를 듣고, 왼쪽 패널에 원문 기록을 계속 이어 붙입니다. 번역 결과는 오른쪽 패널에 표시됩니다.

짧은 실시간 업데이트는 같은 문장 안에서 부드럽게 갱신됩니다. 긴 침묵이 들어와도 새 카드나 새 대화처럼 분리하지 않고 같은 기록 안에서 문단만 나눕니다. 이때 원문과 번역 모두 문단 사이에 빈 줄이 들어가도록 정리합니다.

상단 컨트롤은 텍스트를 줄인 아이콘 바 형태입니다. 캡처가 진행 중일 때는 가운데에 시스템 오디오 데시벨에 반응하는 긴 waveform 미터가 나타나고, 오른쪽에는 정지, 일시정지, 플로팅 자막 토글 버튼만 남아 빠르게 조작할 수 있습니다. 각 컨트롤은 hover/pressed/클릭 완료 피드백과 툴팁, 접근성 라벨을 유지합니다.

`일시정지`는 현재 세션을 유지한 채 입력만 멈춥니다. `정지`는 현재 기록을 저장하되 화면의 현재 세션은 남겨 둡니다. 다음에 새 캡처를 시작하면 새 기록 화면으로 전환됩니다.

원문과 번역 패널은 고정 높이 안에서 각각 스크롤됩니다. 기록이 길어져도 전체 화면 레이아웃이 아래로 밀리지 않으며, 보이지 않는 긴 텍스트는 필요한 영역 중심으로 렌더링합니다. 사용자가 최신 위치에 붙어 있을 때는 하단 페이드가 나타나지 않고, 스크롤로 위쪽 기록을 읽을 때만 위/아래 페이드 마스크가 표시됩니다.

각 패널의 복사 버튼은 원문 또는 번역 내용을 클립보드에 복사합니다. 복사가 성공하면 버튼이 짧게 눌리는 애니메이션과 함께 체크 표시로 바뀌어 클릭 결과를 확인할 수 있습니다.

자동 저장은 JSON이 아니라 기록된 텍스트 그대로 저장합니다. 저장 파일은 `날짜_내용과-관련된-짧은-제목.txt` 형식으로 만들어지고, 같은 이름이 있으면 뒤에 번호를 붙입니다.

`원문 + 번역`으로 저장할 때는 활용하기 쉽도록 원문과 번역을 한 파일에 섞지 않습니다. 같은 기본 파일명 끝에만 `_original.txt`, `_translation.txt`를 붙여 두 파일로 저장하고, 앱의 저장소 목록에서는 하나의 묶음으로 보여 줍니다.

## 플로팅 자막

상태바 아이콘이나 앱 안의 자막 버튼으로 플로팅 자막을 켜고 끌 수 있습니다. 플로팅 자막은 영화 자막처럼 내용 중심으로 보이도록 별도 창에 표시됩니다.

설정할 수 있는 항목:

- 표시 모드: 원문, 원문 + 번역, 번역
- 글자 크기: 작게, 보통, 크게
- 표시 줄 수: 1줄, 2줄, 3줄 이상
- 위치: 자막 창을 길게 잡고 드래그해서 이동

상태바 메뉴는 앱 본창을 강제로 띄우지 않고 플로팅 자막과 캡처 상태를 빠르게 제어하도록 구성했습니다.

## 번역 음성 출력

`음성 출력`을 켜면 번역된 내용을 macOS 음성으로 읽습니다. 같은 문장이 반복해서 들어오는 실시간 기록 특성 때문에, 이미 읽은 문장과 거의 같은 문장은 다시 읽지 않도록 방어합니다.

번역 음성이 나올 때는 원문 재생음보다 번역 음성이 더 잘 들리도록 시스템 출력 볼륨을 낮추는 처리를 함께 수행합니다. macOS와 출력 장치 상태에 따라 완전한 앱별 볼륨 분리는 제한될 수 있습니다.

## 저장 위치

저장된 기록은 사용자 Application Support 폴더에 일반 텍스트 파일로 보관됩니다.

```text
~/Library/Application Support/AirTranslate/Transcripts/*.txt
```

사이드바의 `저장된 기록 관리` 버튼을 누르면 저장소 관리 창이 열립니다. 이 창에서 기록 목록을 확인하고, 선택한 기록을 수정하거나 삭제할 수 있으며, 폴더 버튼으로 Finder에서 저장 폴더를 바로 열 수 있습니다.

저장되는 기록 내용은 `원문`, `원문 + 번역`, `번역` 중 선택할 수 있습니다. `원문 + 번역` 저장본은 파일 시스템에서는 `*_original.txt`와 `*_translation.txt`로 분리되지만, 저장소 관리 창에서는 같은 항목으로 묶이고 오른쪽 편집 영역에서 원문과 번역을 함께 보여 줍니다.

저장소 편집 영역의 반짝이 버튼은 원문과 번역 칸에 각각 붙어 있으며, 누른 칸만 macOS Apple Intelligence Writing Tools로 교정하거나 다시 쓸 수 있게 합니다. 편집기는 plain text 기반으로 동작해 시스템 글쓰기 도구가 저장본 내용을 일반 텍스트로 처리합니다. 저장소 관리 창의 `모두 지우기` 버튼은 확인 절차를 거친 뒤 저장된 기록 파일 전체를 삭제합니다.

## 기록 다듬기

`기록 다듬기` 옵션은 반복 문장을 제거하는 기능이 아닙니다. 음성 인식 과정에서 생긴 어색한 단어, 존재하지 않는 단어, 명확한 오타성 단어를 macOS 맞춤법 후보를 이용해 보수적으로 바로잡는 기능입니다.

이 기능은 긴 침묵이나 일시정지처럼 기록이 잠시 안정되는 시점에 작동합니다. 사용자가 말한 내용 자체를 요약하거나 삭제하지 않도록 설계했습니다.

## 성능 최적화

레이턴시를 줄이기 위해 다음 경로를 정리했습니다.

- Apple Translation 지원 여부 결과 캐시
- 캡처 시작 시 번역 세션 사전 준비
- actor 기반 Apple Translation 서비스 격리
- 최신 요청만 처리하는 비동기 직렬 번역 큐
- 실시간 부분 기록 번역 디바운스 단축
- 긴 입력 폭주 시 불필요한 중간 번역 생략
- 번역 캐시 보관량 확대와 오래된 항목 정리
- 기록 목록과 세션 라인 렌더링에 `LazyVStack` 사용
- 긴 원문/번역 텍스트를 패널 내부 `NSScrollView`로 분리
- 플로팅 자막 텍스트 추출 시 전체 문자열 대신 끝부분 중심으로 스캔
- 화면 텍스트 애니메이션 청크 확대와 지연 축소
- 실시간 부분 기록에서 무거운 문단 정리 반복 호출 제거
- 저장은 기록 중이 아니라 정지/종료 시점에 수행
- 오디오 샘플 버퍼마다 새 PCM 버퍼를 만들지 않고 재사용 링 버퍼 사용
- AudioBufferList 임시 할당을 스택 기반으로 처리
- Int16 오디오 샘플을 블록 단위로 복사

가장 큰 병목 후보였던 오디오 버퍼 변환 경로는 `AVAudioPCMBuffer` 재생성을 줄이는 방향으로 바꿨습니다. 긴 세션에서 눈에 띄던 UI 병목은 기록 화면 전체가 계속 늘어나는 구조를 줄이고, 패널 내부 스크롤과 지연 렌더링으로 분산하는 데 초점을 둡니다.

## 요구 사항

- macOS 26.0 이상
- Swift 6.2 이상
- 시스템 오디오 캡처가 가능한 Mac
- Apple Speech 및 Apple Translation 프레임워크 사용 가능 환경

## 필요한 권한

AirTranslate는 다음 권한이 필요합니다.

- 화면 기록
- 시스템 오디오 녹음
- 음성 인식

이 권한들은 앱의 핵심 기능에 필요한 최소 권한입니다. ScreenCaptureKit 기반 시스템 오디오 캡처 때문에 화면 기록 권한이 필요하지만, AirTranslate는 화면 프레임을 기록으로 저장하지 않고 오디오 샘플만 전사 흐름에 사용합니다.

권한을 처음 허용한 뒤에는 앱을 종료하고 다시 실행해야 macOS 개인정보 보호 설정이 안정적으로 반영됩니다.

권한 상태가 꼬였을 때는 다음 명령으로 AirTranslate 권한을 초기화할 수 있습니다.

```bash
./script/build_and_run.sh --reset-permissions
```

## 실행 방법

일반 실행:

```bash
./script/build_and_run.sh
```

빌드 후 실행 확인:

```bash
./script/build_and_run.sh --verify
```

로그 확인:

```bash
./script/build_and_run.sh --logs
```

SwiftPM 빌드 검증:

```bash
swift build -Xswiftc -warnings-as-errors
```

Codex 앱에서는 `.codex/environments/environment.toml`의 `Run` 액션이 `./script/build_and_run.sh`에 연결되어 있습니다.

## 사용 방법

1. 원문 언어와 번역 언어를 선택합니다.
2. 필요한 경우 모델, 기록 다듬기, 음성 출력, 플로팅 자막 옵션을 조정합니다.
3. 재생 버튼을 눌러 Mac 시스템 오디오 캡처를 시작합니다.
4. Mac에서 영상, 회의, 강의 같은 음성 콘텐츠를 재생합니다.
5. 왼쪽 원문 패널과 오른쪽 번역 패널을 확인합니다.
6. 필요하면 일시정지로 현재 세션을 잠시 멈춥니다.
7. 정지를 누르면 현재 기록이 저장되고, 다음 시작 시 새 기록 화면으로 전환됩니다.
8. `저장된 기록 관리`를 열거나 Finder에서 저장된 텍스트 파일을 확인합니다.

## 소개 페이지

제품 소개용 정적 HTML 페이지가 포함되어 있습니다.

```bash
open intro.html
```

이 페이지는 앱 아이콘과 현재 앱 UI 흐름을 바탕으로 AirTranslate의 핵심 기능을 제품 소개 형식으로 보여줍니다.

## 프로젝트 구조

```text
Package.swift
LICENSE
intro.html
Resources/
  AppIcon.png
  AppIcon.icns
Sources/AirTranslate/
  App/
    AirTranslateApp.swift
  Models/
    AirTranslateWindowID.swift
    AppText.swift
    CaptionLine.swift
    FloatingCaptionDisplayMode.swift
    FloatingCaptionLineCount.swift
    FloatingCaptionTextSize.swift
    IntelligenceModel.swift
    LanguageOption.swift
    SavedTranscript.swift
    SavedTranscriptContentMode.swift
  Services/
    AppleTranslationService.swift
    LiveSpeechTranscriber.swift
    SpeechCaptioner.swift
    SystemAudioCapture.swift
    TranslatedSpeechOutput.swift
    TranslationSessionStore.swift
  Support/
    FloatingCaptionDragSurface.swift
    FloatingCaptionTextFormatter.swift
    FloatingCaptionWindowController.swift
    FloatingWindowConfigurator.swift
    MenuBarPanelController.swift
    MenuBarPanelInstaller.swift
  Views/
    CaptionBoardView.swift
    ContentView.swift
    FloatingCaptionWindowView.swift
    MenuBarStatusView.swift
    SettingsView.swift
    SidebarView.swift
    StreamingTranscriptText.swift
    TranscriptLibraryView.swift
script/
  build_and_run.sh
```

## 핵심 구현

- `SystemAudioCapture`: ScreenCaptureKit으로 Mac 시스템 오디오를 캡처합니다.
- `LiveSpeechTranscriber`: Apple Speech의 `SpeechAnalyzer`와 `SpeechTranscriber`로 실시간 기록을 수행합니다.
- `AppleTranslationService`: actor로 격리된 Apple Translation 프레임워크 번역 작업을 수행합니다.
- `TranslationSessionStore`: 캡처, 기록, 번역, 문단 정리, 중복 partial 전사 방지, 세션 보관, 저장, 음성 출력을 조율합니다.
- `TranslatedSpeechOutput`: 번역 음성 출력, 중복 읽기 방지, 출력 볼륨 완화를 담당합니다.
- `FloatingCaptionWindowController`: 앱 바깥에 표시되는 플로팅 자막 창을 관리합니다.
- `FloatingCaptionTextFormatter`: 플로팅 자막 표시 줄 수와 표시 모드에 맞춰 텍스트를 정리합니다.
- `MenuBarPanelController`: 상태바 빠른 제어 패널을 관리합니다.
- `MenuBarStatusView`: 상태바 아이콘과 현재 상태 표시를 제공합니다.
- `CaptionBoardView`: 현재 세션, 원문/번역 스크롤 패널, 복사 피드백, 데시벨 반응형 waveform 미터, 아이콘형 상단 컨트롤을 표시합니다.
- `SidebarView`: 캡처 제어, 언어 선택, 모델 선택, 저장소 관리 진입점을 제공합니다.
- `TranscriptLibraryView`: 저장된 기록 목록, 저장 내용 선택, 원문/번역별 Apple Intelligence 편집, 삭제, 모두 지우기, 저장 폴더 열기 UI를 모달 창으로 제공합니다.
- `AppText`: macOS 선호 언어에 따라 한국어/영어 UI 문자열을 선택합니다.

## 알려진 한계

- Apple Speech/Translation 지원 언어와 설치된 언어 자산 상태에 따라 동작이 달라질 수 있습니다.
- macOS 개인정보 보호 권한은 서명 상태와 번들 식별자에 민감하므로, 빌드 방식이 바뀌면 권한을 다시 허용해야 할 수 있습니다.
- 시스템 오디오에 다른 앱 음성, 알림음, 번역 음성이 섞이면 기록 결과에도 섞일 수 있습니다.
- 번역 품질과 문장 분리는 Apple 프레임워크 결과에 의존합니다.
- macOS 기본 API만으로는 앱별 원문 오디오와 번역 음성을 완전히 독립 믹싱하기 어렵습니다.

## 개발 메모

이 앱은 로컬 SwiftPM macOS 앱으로 관리합니다. GUI 앱 실행은 raw executable이 아니라 `script/build_and_run.sh`가 만든 `.app` 번들을 통해 수행합니다.

빌드 산출물인 `.build/`와 `dist/`는 git에 포함하지 않습니다.

## 라이선스

AirTranslate는 [MIT License](LICENSE)로 공개됩니다.

별도 표기가 없는 한 이 저장소의 소스 코드, 문서, 스크립트, 포함된 프로젝트 자산은 MIT License 조건에 따라 사용할 수 있습니다.
