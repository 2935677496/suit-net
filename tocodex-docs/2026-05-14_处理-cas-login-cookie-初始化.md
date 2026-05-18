# 处理 DioHttp CAS 登录 Cookie 初始化

## 摘要

- 将 CAS 登录相关的 `PersistCookieJar`、`CookieManager` 和重定向拦截器从 `casLogin` 函数内移动到 `DioHttp` 类中管理。
- 通过 `_getCasCookieJar()` / `_createCasCookieJar()` 缓存异步初始化结果，在需要使用 CookieJar 时 `await` 获取，解决 `getApplicationDocumentsDirectory()` 必须异步调用的问题。
- 增加 `_ensureCasInterceptors()`，确保 Cookie 管理器和重定向拦截器只添加一次，避免多次调用 `casLogin` 时重复注册拦截器。
- 对 `lib/dio_http.dart` 执行了 `dart format`。
- 执行 `flutter analyze`，当前仍有既有 `avoid_print` 和 `lib/home.dart` 未使用变量/方法警告，未发现本次改动相关的编译错误。

## 变更文件

- `lib/dio_http.dart`
