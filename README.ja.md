# Servlet DevContainer

DevContainer を利用した Sevlet 開発環境構築のためのテンプレートプロジェクトです。

## 概要

Windows ローカルに開発環境をインストールするのではなく、コンテナを利用した開発環境の構築を行います。　　
VSCode は Windows ローカルにインストールします。

Docker を利用した開発環境を構築するメリットとしては、以下のようなものが上げられるかと思います。

- プロジェクトに応じた Java のインストールが不要
- Maven 等のビルドツールもインストール不要
- 開発環境のアップデートが比較的簡単になる  
  利用するイメージや Dockerfile を修正すればよい
- devcontainer 設定含めたプロジェクトを( 誰かが ) 作成すれば、他メンバーはこれを再利用できる

当プロジェクトは以下のコンテナで構成されています。

- javadev  
  Java のビルド環境。Java, Maven をインストール
- mariadb  
  DB は MariaDB を利用
- tomcat
  Tomcat コンテナ

war のビルドは javadev コンテナで実施し  
生成した war を tomcat コンテナにマウント  
アプリケーションは db を利用する

という構成です。

VSCode から tomcat のデバッグポートに接続して、インタラクティブデバッグを行う事も可能です。

---

## 環境

以下で構築/テストしています。

- Windows 11
- VSCode
- WSL2 (Ubuntu)
- Docker / docker-compose  
  Docker desktop ではなく、docker-ce を apt でインストールしています

VSCode の Extension は以下を追加して下さい。

- Extention Pack for Java  
  以下が含まれます
  - Language Support for Java(TM) by Red Hat
  - Debugger for Java
  - Test Runner for Java
  - Maven for Java
  - Project Manager for Java
  - IntelliCode
- Remote Development  
  以下が含まれます
  - Remote - SSH
  - Remote - Tunnels
  - Dev containers
  - WSL

---

## 制限

プロジェクトのディレクトリは WSL(Ubuntu) 側のディレクトリである必要がありました。  
Windows 側ディレクトリを WSL(Ubuntu) 側でマウントしている形 ( `/mnt/c/...` で参照される形 ) だと、Dev Container の利用 ( Reopne in container ) でエラーが発生し正しく動作しません

---

## 手順

### プロジェクトを開く

1. WSL2(Ubuntu) を実行します。
2. プロジェクトディレクトリに移動します。

```shell
cd project-root
```

3. VSCode を ( WSL 側から ) 開きます

```shell
code .
```

### 設定変更

詳細な仕様等は devcontainer や docker のマニュアル等を参照してください。

#### .devcontainer

DevContainer を利用するための設定は `.devcontainer` ディレクトリに置いてあるので、ここのファイルを調整してください。

プロジェクト名を調整したり、ポートを変更したりしない場合は、変更の必要はありません。

- compose.yml
  docker compose 設定。普通に compose.yml 設定を書けばよいです。  
  ポート設定等は適宜変更して構いませんが、rebuild.sh 等でも利用しているので、あわせて下さい。
- devcontainer.json
  devcontainer の設定です。  
  殆どの設定は調べれば何をしているかは判ると思います。
  "mounts" 部分は DOOD 設定です。Docker ソケットをマウントし、ホスト(WSL(Ubuntu)) の Docker を javadev コンテナから操作可能に設定しています。Dockerfile で javadev には docker-cli をインストール。
- Dockerfile  
  javadev コンテナのビルド用。  
  devcontainer 提供のコンテナイメージをベースにして、ビルドツール (Maven or Gradle) と docker-cli のインストールを行います。
- .env  
  環境変数  
  PROJECT_NAME を設定しています。.devcontainer 管理下の .env は devcontainer.json で利用できる変数が利用(展開)できるので、これを利用しています。
  PROJECT_NAME の値は pom.xml の `artifactId` と同じに設定してあり、生成される war ファイル名に利用されます。
  war を再配置/リロードする場合には war の展開先ディレクトリを削除しなければならないのですが、この処理を実行するスクリプトが PROJECT_NAME 環境変数を使うようになっています。

#### その他

- rebuild.sh  
  プロジェクトルートにおいてあるシェルスクリプト。
  war のリビルドと、tomcat コンテナの再起動を実行します。devcontainer のメニューからリビルドしても war のリロードは行えるのですが、処理コストが大きいので、tomcat コンテナのみ再起動するようにしています。  
  上述したように POROJECT_NAME 環境変数を利用しているので、これらを変更する場合は適宜調整してください。

### 実行

設定ファイルの確認が終わったら、実際にビルド/実行が行えるか確認してみましょう。

### Dev Container の実行

Dev Container の実行/接続は以下で行えます。

1. VSCode 左下の `>< WSL:Ubuntu` をクリック
2. メニューが開くので `Reopen in Container` を選択

設定ファイルに問題なければ、Dev Container の起動、及び、接続が行われます。

### postCreateCommand の実行

コンテナ生成が無事に行われると、`devcontainer.json` で設定している `postCreateCommand` で定義しているコマンドが実行されます。

TERMINAL ウィンドウに実行結果が出力されます。無事ビルドが行われれば以下が出力されているはずです。

```shell
Running the postCreateCommand from devcontainer.json...

[6985 ms] Start: Run in container: /bin/sh -c cd /workspaces/servlet-devcontainer && echo 'Dev Container 起動 OK !'
Dev Container 起動 OK !
Done. Press any key to close the terminal.
```

`Press any key` しましょう。

`root ➜ /workspaces/servlet-devcontainer $` という形で javadev コンテナのターミナル状態になります。

### war を生成する

javadev コンテナでは、Maven でのビルドが行える状態になっています。

先ずは `ls -la` と叩いて、どのようなファイルがあるか確認してみましょう。
WSL 上のプロジェクトがマウントされているので、プロジェクトと同じファイル/ディレクトリが見えると思います。

ファイルが確認できたら、ビルドしてみましょう。

```shell
mvn clean package
```

プロジェクト自体に問題なければビルドが通り、target ディレクトリ下に war ファイルが生成されます。

### war をマウントする

また、compose.yml で target ディレクトリを tomcat コンテナにマウントするように設定しているので、target 直下に生成される war が tomcat の webapps ディレクトリにマウントされるはずです。

確認するには以下を実行します。  
DOOD 設定を行っているので、コンテナからホストの Docker を操作可能です。

```shell
docker exec -it tomcat ls -la /usr/local/tomcat/webapps
```

ただし、この時点では、以下のように何も表示されなかったのではないかと思います。

```shell
docker exec -it tomcat ls -la /usr/local/tomcat/webapps
total 0
```

これは、war ファイルの生成は tomcat コンテナ起動後に行っているため、tomcat コンテナ側には反映されていないためです。  
生成された war をマウントするためには tomcat コンテナの再起動が必要です。

tomcat コンテナの再起動を行う場合、compose のプロジェクト名を指定する必要があり、これを指定しての

- tomcat コンテナの再起動
- 既に展開されたアプリケーションの削除

等を手動で行うのは面倒なため、これら一連の作業を行うのが上述の `rebuild.sh` になっています。

war をビルドしただけでは war のデプロイがなされない事を実感してもらうために、上記 `docker exec ...` コマンドに関して手順を記載しましたが、war のリビルド、及び、tomcat コンテナの再起動をする場合は以下を実行すれば OK です。

```shell
chmod +x rebuild.sh
./rebuild.sh
```

#### tasks.json

rebuild.sh は tasks.json に設定してあるので、以下の手順でタスクを実行できます。

1. VSCode のメニューから `Terminal` > `Run Task...` をクリック
2. `Rebuild WAR` ( 設定した "label" ) をクリック

また、`"group": "build"` を設定してビルドタスクとして登録しているため、以下の手順も可能です。

1. `Ctrl + Shift + B` を押す
2. ビルドタスクが表示されるので　`Rebuild WAR` を選択する

### 動作確認

動作を確認してみましょう。war ファイルとして展開した場合、ファイル名部分がコンテキストパスになります。

プロジェクト設定を変更していない場合、war ファイル名は `servlet-devcontainer-0.1.war` なので、アプリケーションのベース URL は以下になります。

[http://localhost:8080/servlet-devcontainer-0.1/](http://localhost:8080/servlet-devcontainer-0.1/)

含まれるサンプルサーブレット ( `HelloServlet.java` ) へアクセスする場合は

[http://localhost:8080/servlet-devcontainer-0.1/hello](http://localhost:8080/servlet-devcontainer-0.1/hello) でアクセス可能です。

動作しているか確認しましょう。

### デバッグ

アプリが動作している状態で、VSCode のメニューから `Run` > `Start Debugging` を実行します。

適当なブレークポイントを設定し、ブレークできるか確認してみましょう。

---

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

© 2025 mosaos. All rights reserved.
