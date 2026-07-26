import 'package:gyawun_metadata_sdk/metadata/interfaces/inetwork_service.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_request.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_response.dart';
import 'package:http/http.dart' as http;

class PluginNetworkService implements INetworkService {
  PluginNetworkService();

  @override
  Future<PluginResponse> send(PluginRequest request) async {
    final finalHeaders = {'User-Agent': 'MusicAre/1.0.0'}
      ..addAll(request.headers);

    final uri = Uri.parse(request.url);
    http.Response requestFuture;

    await Future.delayed(const Duration(milliseconds: 1000));
    if (request.method.toUpperCase() == 'POST') {
      requestFuture = await http.post(
        uri,
        headers: finalHeaders,
        body: request.body,
      );
    } else {
      requestFuture = await http.get(uri, headers: finalHeaders);
    }

    final pluginResponse = PluginResponse(
      statusCode: requestFuture.statusCode,
      body: requestFuture.body,
    );

    return pluginResponse;
  }
}
