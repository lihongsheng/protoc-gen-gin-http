{{$svrType := .ServiceType}}
{{$svrName := .ServiceName}}


type {{.ServiceType}}GinHTTPServerProxy struct {
  cc {{.ServiceType}}Client
  responseHandler func(ctx *gin.Context, data interface{}, err error)
}
// New{{.ServiceType}}GinProxy
// 使用原生的 grpc.ClientConnInterface 可以使用原生的 grpc
func New{{.ServiceType}}GinProxy(cc grpc.ClientConnInterface, responseHandler func(ctx *gin.Context, data interface{}, err error)) *{{.ServiceType}}GinHTTPServerProxy {
	return &{{.ServiceType}}GinHTTPServerProxy{cc:New{{.ServiceType}}Client(cc), responseHandler:responseHandler}
}

// New{{.ServiceType}}GinClientProxy
// 传入 Client 可以使用zrpc 的Client
func New{{.ServiceType}}GinClientProxy(cc {{.ServiceType}}Client, responseHandler func(ctx *gin.Context, data interface{}, err error)) *{{.ServiceType}}GinHTTPServerProxy {
	return &{{.ServiceType}}GinHTTPServerProxy{cc:cc, responseHandler:responseHandler}
}

func {{.ServiceType}}GinResponse(ctx *gin.Context, data interface{}, err error) {
    if err != nil {
        ctx.JSON(http.StatusInternalServerError, map[string]interface{}{
            "msg": err.Error(),
        })
    }
	ctx.JSON(http.StatusOK, map[string]interface{}{
		"data": data,
	})
}

{{- range .Methods}}
func (s *{{$.ServiceType}}GinHTTPServerProxy) {{.Name}}{{.Num}}_HTTP_Handler(ctx *gin.Context) {
    var in {{.Request}}
    {{if .HasVars }}
    	if err := ctx.ShouldBindUri(&in); err != nil {
    		s.responseHandler(ctx, nil, err)
    		return
    	}
    {{end}}
    {{if eq .Method "GET" "DELETE" }}
    	if err := ctx.ShouldBindQuery(&in); err != nil {
    		s.responseHandler(ctx, nil, err)
    		return
    	}
    {{else if eq .Method "POST" "PUT" }}
    	if err := ctx.ShouldBindJSON(&in); err != nil {
    		s.responseHandler(ctx, nil, err)
    		return
    	}
    {{else}}
    	if err := ctx.ShouldBind(&in); err != nil {
    		s.responseHandler(ctx, nil, err)
    		return
    	}
    {{end}}
    md := metadata.New(nil)
    for k, v := range ctx.Request.Header {
       md.Set(k, v...)
    }
    newCtx := metadata.NewIncomingContext(ctx, md)
    out, err := s.cc.{{.Name}}(newCtx, &in)
    if err != nil {
        s.responseHandler(ctx, out, err)
        return
    }
    s.responseHandler(ctx, out, err)
}
{{- end}}


func (s *{{.ServiceType}}GinHTTPServerProxy) Register{{.ServiceType}}HTTPServer(group *gin.RouterGroup) {
	{{- range .Methods}}
	group.{{.Method}}("{{.Path}}", s.{{.Name}}{{.Num}}_HTTP_Handler)
	{{- end}}
}
