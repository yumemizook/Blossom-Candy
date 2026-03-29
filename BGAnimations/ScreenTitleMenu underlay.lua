t = Def.ActorFrame{}

local frameX = THEME:GetMetric("ScreenTitleMenu","ScrollerX")-10
local frameY = THEME:GetMetric("ScreenTitleMenu","ScrollerY")



t[#t+1] = LoadFont("Common Normal") .. {
	InitCommand=cmd(xy,5,5;zoom,0.4;valign,0;halign,0;);
	OnCommand=function(self)
		self:settext(string.format("%s %s",ProductFamily(),ProductVersion()));
	end;
}

t[#t+1] = LoadFont("Common Normal") .. {
	InitCommand=cmd(xy,5,16;zoom,0.3;valign,0;halign,0;);
	OnCommand=function(self)
		self:settext(string.format("%s %s",VersionDate(),VersionTime()));
	end;
}

t[#t+1] = LoadFont("Common Normal") .. {
	InitCommand=cmd(xy,5,25;zoom,0.3;valign,0;halign,0;);
	OnCommand=function(self)
		self:settext(string.format("%s Songs in %s Groups",SONGMAN:GetNumSongs(),SONGMAN:GetNumSongGroups()));
	end;
}


return t