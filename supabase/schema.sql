-- 1. Create Tables

-- User Profiles (tersinkronisasi dengan auth.users)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Follow System
CREATE TABLE public.follows (
    follower_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    following_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (follower_id, following_id)
);

-- Playlists
CREATE TABLE public.playlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    is_public BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Playlist Items (Lagu-lagu di dalam playlist)
CREATE TABLE public.playlist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    playlist_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE NOT NULL,
    youtube_id TEXT NOT NULL,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    cover_url TEXT,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Liked Songs
CREATE TABLE public.liked_songs (
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    youtube_id TEXT NOT NULL,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    cover_url TEXT,
    liked_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (user_id, youtube_id)
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.liked_songs ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS Policies

-- User Profiles: Siapapun bisa melihat profil, tapi hanya pemilik yang bisa mengedit
CREATE POLICY "Profiles are viewable by everyone" ON public.user_profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);

-- Follows: Siapapun bisa melihat follower/following, tapi hanya user login yang bisa mem-follow/unfollow atas namanya sendiri
CREATE POLICY "Follows are viewable by everyone" ON public.follows FOR SELECT USING (true);
CREATE POLICY "Users can follow someone" ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can unfollow someone" ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- Playlists: User bisa melihat playlist miliknya atau playlist publik milik orang lain
CREATE POLICY "Playlists are viewable by owner or if public" ON public.playlists FOR SELECT USING (auth.uid() = user_id OR is_public = true);
CREATE POLICY "Users can create playlists" ON public.playlists FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own playlists" ON public.playlists FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own playlists" ON public.playlists FOR DELETE USING (auth.uid() = user_id);

-- Playlist Items: Bisa dilihat jika playlist-nya publik atau milik user sendiri
CREATE POLICY "Playlist items are viewable by owner or if public" ON public.playlist_items FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.playlists 
        WHERE playlists.id = playlist_items.playlist_id 
        AND (playlists.is_public = true OR playlists.user_id = auth.uid())
    )
);
CREATE POLICY "Users can insert items to own playlists" ON public.playlist_items FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.playlists 
        WHERE playlists.id = playlist_items.playlist_id 
        AND playlists.user_id = auth.uid()
    )
);
CREATE POLICY "Users can delete items from own playlists" ON public.playlist_items FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.playlists 
        WHERE playlists.id = playlist_items.playlist_id 
        AND playlists.user_id = auth.uid()
    )
);

-- Liked Songs: Private, hanya user login yang bisa melihat, menambah, atau menghapus lagunya sendiri
CREATE POLICY "Users can view own liked songs" ON public.liked_songs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can add liked songs" ON public.liked_songs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own liked songs" ON public.liked_songs FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove liked songs" ON public.liked_songs FOR DELETE USING (auth.uid() = user_id);

-- 4. Trigger Create Profile Otomatis saat Register (Opsional, tapi sangat disarankan)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, avatar_url)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)), -- Default username dari email
    COALESCE(new.raw_user_meta_data->>'avatar_url', '')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
