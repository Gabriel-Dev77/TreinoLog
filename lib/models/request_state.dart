/// Estados possíveis de uma comunicação com um serviço pela rede.
///
/// Usar uma classe `sealed` obriga as telas a tratar TODOS os casos
/// no `switch` — o compilador avisa se algum estado for esquecido.
sealed class RequestState<T> {
  const RequestState();
}

/// Nada foi pedido ainda (ex: campo de busca vazio).
class RequestIdle<T> extends RequestState<T> {
  const RequestIdle();
}

/// Requisição em andamento.
class RequestLoading<T> extends RequestState<T> {
  const RequestLoading();
}

/// Resposta recebida com dados.
class RequestSuccess<T> extends RequestState<T> {
  final T data;
  const RequestSuccess(this.data);
}

/// Resposta recebida, mas sem nenhum dado (ex: busca sem resultados).
class RequestEmpty<T> extends RequestState<T> {
  const RequestEmpty();
}

/// A requisição falhou (sem rede, servidor fora do ar, resposta inválida...).
class RequestError<T> extends RequestState<T> {
  final String mensagem;
  const RequestError(this.mensagem);
}
