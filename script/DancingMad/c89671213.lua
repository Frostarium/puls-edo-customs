--Statue of the Gods
local s,id=GetID()
local CARD_GODDESS_WARRING_TRIAD=89671211
local CARD_FIEND_WARRING_TRIAD=89671216
local CARD_FIENDS_AURA_FORCE_FIELD=89671218
local CARD_KEFKAS_ILLUSION=89671214
local CARD_TYRFING=89671217
s.listed_names={CARD_GODDESS_WARRING_TRIAD,CARD_FIEND_WARRING_TRIAD,CARD_FIENDS_AURA_FORCE_FIELD,CARD_KEFKAS_ILLUSION,CARD_TYRFING}
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--When "Goddess of the Warring Triad" or "Fiend of the Warring Triad" activates an effect, or "Fiend's Aura Force Field" activates its card type effect, toss a coin
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if rp~=tp then return false end
	if not re:IsMonsterEffect() then
		return (rc:IsOriginalCode(CARD_FIENDS_AURA_FORCE_FIELD) and re:GetDescription()==aux.Stringid(CARD_FIENDS_AURA_FORCE_FIELD,1))
			or (rc:IsOriginalCode(CARD_TYRFING) and re:IsHasType(EFFECT_TYPE_IGNITION))	end
	return (re:IsHasType(EFFECT_TYPE_QUICK_O) and rc:IsOriginalCode(CARD_GODDESS_WARRING_TRIAD))
		or (re:IsHasType(EFFECT_TYPE_QUICK_O) and rc:IsOriginalCode(CARD_FIEND_WARRING_TRIAD))
		or (re:IsHasType(EFFECT_TYPE_QUICK_O) and rc:IsOriginalCode(CARD_KEFKAS_ILLUSION))
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	--Tails: the Goddess applies her effect to all monsters your opponent controls instead; the Fiend summons to your field and places its monster in your backrow instead;
	--"Fiend's Aura Force Field" lets you declare a 2nd card type; the monster "Kefka's Illusion" targets Special Summons itself to your field as a Zombie when it negates
	--(each checks this flag and the chain link in its own effect)
	if Duel.TossCoin(tp,1)==COIN_TAILS then
		re:GetHandler():RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD|RESET_CHAIN,0,1,ev)
	end
end
