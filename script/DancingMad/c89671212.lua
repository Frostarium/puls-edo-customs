--Cloudy Heaven
local s,id,o=GetID()
local COUNTER_DOOM=0x1637
local SET_WARRING_TRIAD=0x1613
local CARD_GODDESS_WARRING_TRIAD=89671211
local TOKEN_MAGICITE=89671220
--flag effect codes, kept apart from the ones other Warring Triad cards register on monsters
local FLAG_APPLIER=id+1000
local FLAG_PERMA=id+1001
s.listed_names={CARD_GODDESS_WARRING_TRIAD,TOKEN_MAGICITE}
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--During your Main Phase: add 1 "Warring Triad" card from your Deck to your hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--Discard 1 card; Special Summon 2 "Magicite Tokens", then immediately Link Summon "Goddess of the Warring Triad"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.discost)
	e2:SetTarget(s.tktg)
	e2:SetOperation(s.tkop)
	c:RegisterEffect(e2)
	--While this card is face-up on the field, "Goddess of the Warring Triad" can place Doom Counters instead of Enticement Counters (see its script)
	--During each End Phase (either player's), remove 1 Doom Counter from each monster with any. A monster that loses its last one is destroyed, and comes back as a Zombie on the side of the player who applied the counters
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_PHASE+PHASE_END)
		ge1:SetCountLimit(1)
		ge1:SetCondition(s.doomcon)
		ge1:SetOperation(s.doomop)
		Duel.RegisterEffect(ge1,0)
	end)
end
s.counter_place_list={COUNTER_DOOM}
--search
function s.thfilter(c)
	return c:IsSetCard(SET_WARRING_TRIAD) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
--shared cost: discard 1 card
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST|REASON_DISCARD)
end
--tokens + Link Summon
function s.gdsfilter(c)
	--only checks that she is in the Extra Deck: she cannot be tested against the Tokens before they exist
	return c:IsCode(CARD_GODDESS_WARRING_TRIAD)
end
function s.lkfilter(c,mg)
	return c:IsCode(CARD_GODDESS_WARRING_TRIAD) and c:IsLinkSummonable(nil,mg)
end
function s.tkcheck(tp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
		and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_MAGICITE,nil,TYPES_TOKEN,0,0,3,RACE_FAIRY,ATTRIBUTE_LIGHT)
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.tkcheck(tp) and Duel.IsExistingMatchingCard(s.gdsfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if not s.tkcheck(tp) then return end
	local tg=Group.CreateGroup()
	for i=1,2 do
		local token=Duel.CreateToken(tp,TOKEN_MAGICITE)
		--Level 3 LIGHT Fairy 0/0, set here instead of in the database
		token:Level(3)
		token:Race(RACE_FAIRY)
		token:Attribute(ATTRIBUTE_LIGHT)
		token:Attack(0)
		token:Defense(0)
		if Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP) then
			tg:AddCard(token)
		end
	end
	Duel.SpecialSummonComplete()
	tg=tg:Filter(Card.IsLocation,nil,LOCATION_MZONE)
	if #tg<2 then return end
	--immediately Link Summon "Goddess of the Warring Triad" using those Tokens
	local lg=Duel.GetMatchingGroup(s.lkfilter,tp,LOCATION_EXTRA,0,nil,tg)
	if #lg==0 then return end
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=lg:Select(tp,1,1,nil):GetFirst()
	Duel.LinkSummon(tp,sc,nil,tg)
end
--Doom Counters
--called by "Goddess of the Warring Triad" when she places Doom Counters (with this card face-up on your field)
function s.cloudyfilter(c)
	return c:IsFaceup() and c:IsCode(id)
end
--(whether you control a face-up "Cloudy Heaven")
function s.active(tp)
	return Duel.IsExistingMatchingCard(s.cloudyfilter,tp,LOCATION_ONFIELD,0,1,nil)
end
--places the counters on tc, and remembers who applied them (the dead come back on that player's side)
--and whether the coin toss of "Statue of the Gods" was tails (they come back on their own side as puppets instead, see s.puppet)
function s.place(tc,tp,ct,tails)
	if not tc:AddCounter(COUNTER_DOOM,ct) then return false end
	tc:ResetFlagEffect(FLAG_APPLIER)
	tc:RegisterFlagEffect(FLAG_APPLIER,RESET_EVENT|RESETS_STANDARD,0,1,tp)
	tc:ResetFlagEffect(FLAG_PERMA)
	if tails then
		tc:RegisterFlagEffect(FLAG_PERMA,RESET_EVENT|RESETS_STANDARD,0,1,tp)
	end
	return true
end
function s.doomfilter(c)
	return c:GetCounter(COUNTER_DOOM)>0
end
function s.doomcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.doomfilter,0,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end
function s.doomop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.doomfilter,0,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g==0 then return end
	Duel.Hint(HINT_CARD,0,id)
	--the player each monster's Doom Counters belong to, and whether it becomes a Zombie permanently (read now: both are lost when the monster leaves the field)
	local owners={}
	local perma={}
	local dead=Group.CreateGroup()
	for tc in g:Iter() do
		tc:RemoveCounter(tc:GetControler(),COUNTER_DOOM,1,REASON_EFFECT)
		if tc:GetCounter(COUNTER_DOOM)==0 then
			dead:AddCard(tc)
			owners[tc]=tc:GetFlagEffectLabel(FLAG_APPLIER)
			perma[tc]=tc:HasFlagEffect(FLAG_PERMA)
		end
	end
	if #dead==0 then return end
	Duel.Destroy(dead,REASON_EFFECT)
	--the monsters that died come back as Zombies on the side of the player who applied the counters
	--("Statue of the Gods" tails: they come back on their own side instead, as puppets that must attack their own side's monsters)
	local gy=Duel.GetOperatedGroup():Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	local pg,ng=gy:Split(function(c) return perma[c] end,nil)
	gy=ng
	for p=0,1 do
		local rg=pg:Filter(function(c) return c:GetPreviousControler()==p and c:IsCanBeSpecialSummoned(e,0,1-p,false,false,POS_FACEUP_ATTACK,p) end,nil)
		local ft=Duel.GetMZoneCount(p)
		if #rg>0 and ft>0 then
			if #rg>ft then
				Duel.Hint(HINT_SELECTMSG,1-p,HINTMSG_SPSUMMON)
				rg=rg:Select(1-p,ft,ft,nil)
			end
			for tc in rg:Iter() do
				if Duel.SpecialSummonStep(tc,0,1-p,p,false,false,POS_FACEUP_ATTACK) then
					s.zombify(e:GetHandler(),tc)
					s.puppet(e:GetHandler(),tc,1-p)
				end
			end
			Duel.SpecialSummonComplete()
		end
	end
	for p=0,1 do
		local rg=gy:Filter(function(c) return owners[c]==p and c:IsCanBeSpecialSummoned(e,0,p,false,false) end,nil)
		local ft=Duel.GetMZoneCount(p)
		if #rg>0 and ft>0 then
			if #rg>ft then
				Duel.Hint(HINT_SELECTMSG,p,HINTMSG_SPSUMMON)
				rg=rg:Select(p,ft,ft,nil)
			end
			for tc in rg:Iter() do
				if Duel.SpecialSummonStep(tc,0,p,p,false,false,POS_FACEUP) then
					s.zombify(e:GetHandler(),tc)
				end
			end
			Duel.SpecialSummonComplete()
		end
	end
end
--Zombie that cannot be Tributed or used as material for an Extra Deck Summon
function s.zombify(c,tc)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_RACE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(RACE_ZOMBIE)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UNRELEASABLE_SUM)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetValue(1)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	tc:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e4:SetValue(aux.cannotmatfilter(SUMMON_TYPE_FUSION,SUMMON_TYPE_SYNCHRO,SUMMON_TYPE_XYZ,SUMMON_TYPE_LINK))
	tc:RegisterEffect(e4)
end
--"Statue of the Gods" tails: a puppet. 0 DEF, always in Attack Position, must attack, and attacks another monster on its own side
--(including another puppet) instead; cannot attack if there is none. "activator" is the player who picks which monster it attacks
function s.puppet(c,tc,activator)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_DEFENSE_FINAL)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(0)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_SET_POSITION)
	e2:SetValue(POS_FACEUP_ATTACK)
	tc:RegisterEffect(e2)
	local e3=e1:Clone()
	e3:SetCode(EFFECT_MUST_ATTACK)
	e3:SetValue(1)
	tc:RegisterEffect(e3)
	local e4=e1:Clone()
	e4:SetCode(EFFECT_CANNOT_ATTACK)
	e4:SetValue(1)
	e4:SetCondition(s.nopcon)
	tc:RegisterEffect(e4)
	--when it attacks, the battle is redirected to one of the monsters on its own side
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_BATTLE_CONFIRM)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetLabel(activator)
	e5:SetCondition(s.pupcon)
	e5:SetOperation(s.pupop)
	e5:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e5)
end
--monsters a puppet could attack: any other monster its controller has (puppets included)
function s.victimfilter(c,a)
	return c~=a
end
function s.nopcon(e)
	local c=e:GetHandler()
	return not Duel.IsExistingMatchingCard(s.victimfilter,c:GetControler(),LOCATION_MZONE,0,1,nil,c)
end
function s.pupcon(e)
	local a=Duel.GetAttacker()
	return a==e:GetHandler() and not s.nopcon(e)
end
function s.pupop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	if not a:CanAttack() or a:IsImmuneToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.victimfilter,a:GetControler(),LOCATION_MZONE,0,nil,a)
	local tc=g:GetFirst()
	if #g>1 then
		local p=e:GetLabel()
		Duel.Hint(HINT_SELECTMSG,p,HINTMSG_ATTACKTARGET)
		tc=g:Select(p,1,1,nil):GetFirst()
	end
	Duel.HintSelection(tc)
	Duel.CalculateDamage(a,tc)
end
