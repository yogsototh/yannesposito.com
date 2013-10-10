% DPI 180
gu:=2u;
z0=origin;
z1=z0 shifted (0,-gu);

drawState(z0,"\mathtt{fact}");
drawState(z1,"2");
drawarrow edge(z0,z1);
