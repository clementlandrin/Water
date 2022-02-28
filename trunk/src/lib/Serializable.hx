package lib;

typedef Serializable = #if network hxbit.NetworkSerializable #else hxbit.Serializable #end;
