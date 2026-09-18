import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import '../config/api_config.dart';

/// [cookieJar] porte le cookie HttpOnly `gt_auth` (JWT) posé par
/// AuthController — voir AuthCookieService côté Spring. C'est exactement le
/// mécanisme que le frontend Next.js délègue au navigateur (`withCredentials:
/// true`) ; ici [CookieManager] le rejoue à la main pour chaque requête.
class DioClient {
  final Dio _dio;

  DioClient(CookieJar cookieJar) : _dio = Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (ApiConfig.enableHttpLogging) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }

    _dio.interceptors.add(CookieManager(cookieJar));

    _dio.interceptors.add(
      InterceptorsWrapper(
        // Contrairement à axios côté Next.js (`withXSRFToken: true` +
        // `xsrfCookieName`/`xsrfHeaderName`), Dio ne recopie pas tout seul un
        // cookie lisible vers un header - il faut le faire à la main. Spring
        // Security (CsrfFilter, voir SecurityConfig#CSRF_IGNORED_ENDPOINTS
        // côté Java) exige un header X-XSRF-TOKEN égal au cookie XSRF-TOKEN
        // sur toute requête mutante (POST/PUT/PATCH/DELETE) hors endpoints
        // explicitement exemptés (auth/search/bookings/payments/tickets/...) ;
        // sans ça, ces requêtes échouent en 403 même avec une session valide
        // (ex: PATCH /api/notifications/{id}/read). Envoyé sur toute requête,
        // pas seulement les mutantes, comme le fait axios par défaut - un
        // header en trop sur un GET est inoffensif, Spring ne le vérifie que
        // pour les méthodes mutantes.
        onRequest: (options, handler) async {
          final cookies = await cookieJar.loadForRequest(options.uri);
          final xsrfCookies = cookies.where((c) => c.name == 'XSRF-TOKEN');
          if (xsrfCookies.isNotEmpty) {
            options.headers['X-XSRF-TOKEN'] = xsrfCookies.last.value;
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
