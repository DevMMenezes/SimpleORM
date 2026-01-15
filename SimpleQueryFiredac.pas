unit SimpleQueryFiredac;

interface

uses
  SimpleInterface, FireDAC.Comp.Client, System.Classes, Data.DB,
  FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet;

Type
  TSimpleQueryFiredac = class(TInterfacedObject, iSimpleQuery)
  private
    FConnection: TFDConnection;
    FTransaction: TFDTransaction;
    FQuery: TFDQuery;
    FParams: TParams;
  public
    constructor Create(aConnection: TFDConnection);
    destructor Destroy; override;
    class function New(aConnection: TFDConnection): iSimpleQuery;
    function SQL: TStrings;
    function Params: TParams;
    function ExecSQL: iSimpleQuery;
    function DataSet: TDataSet;
    function Open(aSQL: String): iSimpleQuery; overload;
    function Open: iSimpleQuery; overload;
    function &EndTransaction: iSimpleQuery;
    function RowsAffected: Integer;
  end;

implementation

uses
  System.SysUtils;

{ TSimpleQuery<T> }

constructor TSimpleQueryFiredac.Create(aConnection: TFDConnection);
begin
  FQuery := TFDQuery.Create(nil);
  FConnection := aConnection;
  FQuery.Connection := FConnection;

  FTransaction := TFDTransaction.Create(nil);
  FTransaction.Connection := FConnection;

  FQuery.Transaction := FTransaction;

  if FTransaction.Active then
    FTransaction.Commit;
  FTransaction.StartTransaction;
end;

function TSimpleQueryFiredac.DataSet: TDataSet;
begin
  Result := TDataSet(FQuery);
end;

destructor TSimpleQueryFiredac.Destroy;
begin
  FreeAndNil(FTransaction);
  FreeAndNil(FQuery);
  if Assigned(FParams) then
    FreeAndNil(FParams);
  inherited;
end;

function TSimpleQueryFiredac.EndTransaction: iSimpleQuery;
begin
  if FTransaction.Active then
    FTransaction.Commit;
end;

function TSimpleQueryFiredac.ExecSQL: iSimpleQuery;
begin
  Result := Self;
  if Assigned(FParams) then
    FQuery.Params.Assign(FParams);
  try
    FQuery.Prepare;

    try
      FQuery.ExecSQL;
    except
      on E: Exception do
      begin
        FTransaction.Rollback;
        raise Exception.Create(E.Message);
      end;
    end;
  finally
    if Assigned(FParams) then
      FreeAndNil(FParams);
  end;
end;

class function TSimpleQueryFiredac.New(aConnection: TFDConnection)
  : iSimpleQuery;
begin
  Result := Self.Create(aConnection);
end;

function TSimpleQueryFiredac.Open: iSimpleQuery;
begin
  Result := Self;
  FQuery.Close;

  if Assigned(FParams) then
    FQuery.Params.Assign(FParams);

  FQuery.Prepare;
  FQuery.Open;

  if Assigned(FParams) then
    FreeAndNil(FParams);
end;

function TSimpleQueryFiredac.Open(aSQL: String): iSimpleQuery;
begin
  Result := Self;
  FQuery.Close;
  FQuery.Open(aSQL);
end;

function TSimpleQueryFiredac.Params: TParams;
begin
  if not Assigned(FParams) then
  begin
    FParams := TParams.Create(nil);
    FParams.Assign(FQuery.Params);
  end;
  Result := FParams;
end;

function TSimpleQueryFiredac.RowsAffected: Integer;
begin
  if Assigned(FQuery) then
    Result := FQuery.RowsAffected;
end;

function TSimpleQueryFiredac.SQL: TStrings;
begin
  Result := FQuery.SQL;
end;

end.
