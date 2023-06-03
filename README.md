# Infrastructure for Hackers Ground

해커그라운드 운영을 위한 인프라스트럭처 리포지토리입니다

## 전체 아키텍처

![전체 아키텍처](./assets/architecture.png)

## 사전 준비물

- [애저 구독](https://azure.microsoft.com/ko-kr/free/?WT.mc_id=dotnet-91712-juyoo)
- [애저 CLI](https://learn.microsoft.com/ko-kr/cli/azure/what-is-azure-cli?WT.mc_id=dotnet-91712-juyoo)
- [애저 Dev CLI](https://learn.microsoft.com/ko-kr/azure/developer/azure-developer-cli/overview?WT.mc_id=dotnet-91712-juyoo)
- [GitHub CLI](https://docs.github.com/ko/github-cli/github-cli/about-github-cli)

## 시작하기

1. 자신의 GitHub 계정으로 리포지토리를 포크합니다.
1. 아래 순서대로 명령어를 실행시켜 전체 인프라를 구성합니다.

    ```powershell
    # On Windows
    $AZURE_ENV_NAME = "{{애저 리소스 이름}}"
    $AZURE_ENV_INFRA = "{{애저 배포 환경: dev|test|prod}}"
    ```

    ```bash
    # On MacOS/Linux
    AZURE_ENV_NAME="{{애저 리소스 이름}}"
    AZURE_ENV_INFRA="{{애저 배포 환경: dev|test|prod}}"
    ```

    ```bash
    azd auth login
    azd init -e $AZURE_ENV_NAME
    azd env set AZURE_ENV_INFRA $AZURE_ENV_INFRA
    azd up
    ```

1. 아래 순서대로 명령어를 실행시켜 애플리케이션을 배포합니다.

    ```powershell
    $GITHUB_USERNAME = "{{자신의 GitHub ID}}"
    ```

    ```bash
    GITHUB_USERNAME="{{자신의 GitHub ID}}"
    ```

    ```bash
    azd pipeline config

    gh auth login
    gh workflow run "Azure Deployment" --repo $GITHUB_USERNAME/infrastructure
    ```

    > 위의 `gh workflow run ...` 명령어를 실행시킬 때, 권한 이슈가 나오는 경우 (예: `Resource not accessible by integration`), [퍼스널 액세스 토큰](https://docs.github.com/ko/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)을 사용해 보세요.
    